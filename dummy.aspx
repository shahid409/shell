<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head>
    <title>Simple File Upload</title>
    <style>
        body { font-family: Arial; background:#f5f5f5; color:#333; padding:20px; }
        .msg { margin-top:10px; font-weight:bold; color:green; }
    </style>
</head>
<body>
    <form runat="server" enctype="multipart/form-data">
        <h2>Upload a File</h2>
        <asp:FileUpload runat="server" ID="fuFile" />
        <asp:Button runat="server" Text="Upload" OnClick="BtnUpload_Click" />
        <br />
        <asp:Label runat="server" ID="lblMessage" CssClass="msg" />
        <script runat="server">
            protected void BtnUpload_Click(object sender, EventArgs e)
            {
                if (fuFile.HasFile)
                {
                    try
                    {
                        // Save the file in the same folder as the ASPX page
                        string fileName = System.IO.Path.GetFileName(fuFile.FileName);
                        string savePath = Server.MapPath("./" + fileName);
                        fuFile.SaveAs(savePath);

                        // Generate public URL
                        string fileUrl = Request.Url.GetLeftPart(UriPartial.Authority) +
                                         Request.ApplicationPath.TrimEnd('/') + "/" + fileName;

                        lblMessage.Text = "File uploaded successfully: <a href='" + fileUrl + "'>" + fileUrl + "</a>";
                    }
                    catch (Exception ex)
                    {
                        lblMessage.Text = "Upload failed: " + ex.Message;
                    }
                }
                else
                {
                    lblMessage.Text = "No file selected.";
                }
            }
        </script>
    </form>
</body>
</html>
