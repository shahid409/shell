<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head><title>Simple File Manager with Edit, Rename, Create Folder</title></head>
<body>
    <form runat="server" enctype="multipart/form-data">
        <asp:Label ID="lblCurrentPath" runat="server" Text=""></asp:Label><br /><br />

        <!-- Upload -->
        <asp:FileUpload ID="fuUpload" runat="server" />
        <asp:Button ID="btnUpload" runat="server" Text="Upload File" OnClick="btnUpload_Click" /><br /><br />

        <!-- Create Folder -->
        Folder Name: <asp:TextBox ID="txtNewFolder" runat="server" />
        <asp:Button ID="btnCreateFolder" runat="server" Text="Create Folder" OnClick="btnCreateFolder_Click" /><br /><br />

        <asp:Label ID="lblMessage" runat="server" ForeColor="Green"></asp:Label>
        <asp:Label ID="lblError" runat="server" ForeColor="Red"></asp:Label><br />

        <asp:Literal ID="ltFiles" runat="server"></asp:Literal>

        <!-- File edit area -->
        <asp:Panel ID="pnlEdit" runat="server" Visible="false" style="margin-top:20px; border:1px solid #ccc; padding:10px; width:80%;">
            <asp:Label ID="lblEditFileName" runat="server" Text=""></asp:Label><br /><br />
            <asp:TextBox ID="txtFileContent" runat="server" TextMode="MultiLine" Rows="15" Columns="80"></asp:TextBox><br /><br />
            <asp:Button ID="btnSaveEdit" runat="server" Text="Save File" OnClick="btnSaveEdit_Click" />
            <asp:Button ID="btnCancelEdit" runat="server" Text="Cancel" OnClick="btnCancelEdit_Click" />
        </asp:Panel>

        <asp:HiddenField ID="hfPath" runat="server" />
        <asp:HiddenField ID="hfEditFilePath" runat="server" />

    </form>

<script runat="server">

string RootPath = "";
string CurrentPath = "";

protected void Page_Load(object sender, EventArgs e)
{
    RootPath = Server.MapPath("/");
    CurrentPath = Request.QueryString["path"] ?? "";
    CurrentPath = CurrentPath.Replace("..", ""); // Basic security

    hfPath.Value = CurrentPath;

    lblCurrentPath.Text = "Current Path: " + (string.IsNullOrEmpty(CurrentPath) ? RootPath : Server.MapPath(CurrentPath));

    if (!IsPostBack)
    {
        ShowFilesAndFolders();
    }

    // Handle Download
    string download = Request.QueryString["download"];
    if (!string.IsNullOrEmpty(download))
    {
        string filePath = System.IO.Path.Combine(RootPath, download.Replace("/", "\\"));
        if (System.IO.File.Exists(filePath))
        {
            Response.Clear();
            Response.ContentType = "application/octet-stream";
            Response.AppendHeader("Content-Disposition", "attachment; filename=" + System.IO.Path.GetFileName(filePath));
            Response.TransmitFile(filePath);
            Response.End();
        }
    }

    // Handle Delete
    string del = Request.QueryString["delete"];
    if (!string.IsNullOrEmpty(del))
    {
        string filePath = System.IO.Path.Combine(RootPath, del.Replace("/", "\\"));
        try
        {
            if (System.IO.Directory.Exists(filePath))
                System.IO.Directory.Delete(filePath, true);
            else if (System.IO.File.Exists(filePath))
                System.IO.File.Delete(filePath);
            lblMessage.Text = "Deleted successfully.";
        }
        catch (Exception ex)
        {
            lblError.Text = "Delete error: " + ex.Message;
        }
        ShowFilesAndFolders();
    }

    // Handle Edit (show edit panel)
    string edit = Request.QueryString["edit"];
    if (!string.IsNullOrEmpty(edit))
    {
        string filePath = System.IO.Path.Combine(RootPath, edit.Replace("/", "\\"));
        if (System.IO.File.Exists(filePath))
        {
            hfEditFilePath.Value = edit;
            lblEditFileName.Text = "Editing: " + edit;
            txtFileContent.Text = System.IO.File.ReadAllText(filePath);
            pnlEdit.Visible = true;
        }
    }
}

void ShowFilesAndFolders()
{
    try
    {
        string fullPath = System.IO.Path.Combine(RootPath, CurrentPath.Replace("/", "\\"));
        if (!fullPath.StartsWith(RootPath)) fullPath = RootPath; // Security

        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        sb.Append("<table border='1' cellpadding='5'><tr><th>Name</th><th>Type</th><th>Rename</th><th>Actions</th></tr>");

        // Parent folder link
        if (!string.IsNullOrEmpty(CurrentPath))
        {
            string parent = System.IO.Path.GetDirectoryName(CurrentPath.Replace("/", "\\")).Replace("\\", "/");
            sb.Append($"<tr><td><a href='?path={parent}'>.. (Parent Folder)</a></td><td>Folder</td><td></td><td></td></tr>");
        }

        // Directories
        int idx = 0;
        foreach (string dir in System.IO.Directory.GetDirectories(fullPath))
        {
            string name = new System.IO.DirectoryInfo(dir).Name;
            string rel = CombinePath(CurrentPath, name);
            sb.Append("<tr>");
            sb.Append($"<td><a href='?path={rel}'>{name}</a></td>");
            sb.Append("<td>Folder</td>");
            // Rename inline form
            sb.Append("<td>");
            sb.Append($"<form method='post' style='margin:0;'>");
            sb.Append($"<input type='hidden' name='oldname' value='{rel}' />");
            sb.Append($"<input type='text' name='newname' value='{name}' style='width:120px;' />");
            sb.Append($"<input type='submit' name='rename' value='Rename' />");
            sb.Append("</form>");
            sb.Append("</td>");
            sb.Append("<td>");
            sb.Append($"<a href='?delete={rel}' onclick=\"return confirm('Delete folder {name}?');\">Delete</a>");
            sb.Append("</td>");
            sb.Append("</tr>");
            idx++;
        }

        // Files
        foreach (string file in System.IO.Directory.GetFiles(fullPath))
        {
            string name = System.IO.Path.GetFileName(file);
            string rel = CombinePath(CurrentPath, name);

            sb.Append("<tr>");
            sb.Append($"<td>{name}</td>");
            sb.Append("<td>File</td>");
            // Rename inline form
            sb.Append("<td>");
            sb.Append($"<form method='post' style='margin:0;'>");
            sb.Append($"<input type='hidden' name='oldname' value='{rel}' />");
            sb.Append($"<input type='text' name='newname' value='{name}' style='width:120px;' />");
            sb.Append($"<input type='submit' name='rename' value='Rename' />");
            sb.Append("</form>");
            sb.Append("</td>");
            sb.Append("<td>");
            sb.Append($"<a href='?download={rel}'>Download</a> | ");
            sb.Append($"<a href='?edit={rel}'>Edit</a> | ");
            sb.Append($"<a href='?delete={rel}' onclick=\"return confirm('Delete file {name}?');\">Delete</a>");
            sb.Append("</td>");
            sb.Append("</tr>");
        }

        sb.Append("</table>");
        ltFiles.Text = sb.ToString();
    }
    catch (Exception ex)
    {
        lblError.Text = "Error: " + ex.Message;
    }
}

string CombinePath(string basePath, string add)
{
    if (string.IsNullOrEmpty(basePath)) return add;
    return basePath.TrimEnd('/') + "/" + add;
}

protected void btnUpload_Click(object sender, EventArgs e)
{
    lblMessage.Text = "";
    lblError.Text = "";

    if (!fuUpload.HasFile)
    {
        lblError.Text = "Select a file first.";
        return;
    }

    try
    {
        string fullPath = System.IO.Path.Combine(RootPath, CurrentPath.Replace("/", "\\"));
        if (!fullPath.StartsWith(RootPath)) fullPath = RootPath; // Security

        string savePath = System.IO.Path.Combine(fullPath, System.IO.Path.GetFileName(fuUpload.FileName));
        fuUpload.SaveAs(savePath);
        lblMessage.Text = "File uploaded successfully.";
    }
    catch (Exception ex)
    {
        lblError.Text = "Upload error: " + ex.Message;
    }

    ShowFilesAndFolders();
}

protected void btnCreateFolder_Click(object sender, EventArgs e)
{
    lblMessage.Text = "";
    lblError.Text = "";

    string newFolder = txtNewFolder.Text.Trim();
    if (string.IsNullOrEmpty(newFolder))
    {
        lblError.Text = "Folder name cannot be empty.";
        return;
    }

    try
    {
        string fullPath = System.IO.Path.Combine(RootPath, CurrentPath.Replace("/", "\\"));
        if (!fullPath.StartsWith(RootPath)) fullPath = RootPath; // Security

        string folderPath = System.IO.Path.Combine(fullPath, newFolder);
        if (!System.IO.Directory.Exists(folderPath))
        {
            System.IO.Directory.CreateDirectory(folderPath);
            lblMessage.Text = "Folder created successfully.";
            txtNewFolder.Text = "";
        }
        else
        {
            lblError.Text = "Folder already exists.";
        }
    }
    catch (Exception ex)
    {
        lblError.Text = "Create folder error: " + ex.Message;
    }

    ShowFilesAndFolders();
}

protected override void OnLoadComplete(EventArgs e)
{
    base.OnLoadComplete(e);

    // Handle Rename form post
    if (IsPostBack && Request.Form["rename"] != null)
    {
        string oldName = Request.Form["oldname"];
        string newName = Request.Form["newname"];

        if (!string.IsNullOrEmpty(oldName) && !string.IsNullOrEmpty(newName))
        {
            oldName = oldName.Replace("/", "\\");
            newName = newName.Replace("/", "\\");
            string oldFullPath = System.IO.Path.Combine(RootPath, oldName);
            string newFullPath = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(oldFullPath), newName);

            try
            {
                if (System.IO.File.Exists(newFullPath) || System.IO.Directory.Exists(newFullPath))
                {
                    lblError.Text = "A file or folder with that name already exists.";
                }
                else
                {
                    if (System.IO.Directory.Exists(oldFullPath))
                        System.IO.Directory.Move(oldFullPath, newFullPath);
                    else if (System.IO.File.Exists(oldFullPath))
                        System.IO.File.Move(oldFullPath, newFullPath);

                    lblMessage.Text = "Renamed successfully.";
                }
            }
            catch (Exception ex)
            {
                lblError.Text = "Rename failed: " + ex.Message;
            }
            ShowFilesAndFolders();
        }
    }
}

protected void btnSaveEdit_Click(object sender, EventArgs e)
{
    lblMessage.Text = "";
    lblError.Text = "";

    string editPath = hfEditFilePath.Value;
    if (string.IsNullOrEmpty(editPath))
    {
        lblError.Text = "No file to save.";
        return;
    }

    try
    {
        string fullPath = System.IO.Path.Combine(RootPath, editPath.Replace("/", "\\"));
        System.IO.File.WriteAllText(fullPath, txtFileContent.Text);
        lblMessage.Text = "File saved successfully.";
        pnlEdit.Visible = false;
        Response.Redirect(Request.Url.GetLeftPart(UriPartial.Path) + "?path=" + CurrentPath);
    }
    catch (Exception ex)
    {
        lblError.Text = "Save failed: " + ex.Message;
    }
}

protected void btnCancelEdit_Click(object sender, EventArgs e)
{
    pnlEdit.Visible = false;
    Response.Redirect(Request.Url.GetLeftPart(UriPartial.Path) + "?path=" + CurrentPath);
}

</script>
</body>
</html>
