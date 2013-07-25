public class MobileProductPickerServices
{
	
	public static Id mobileProductPickerFolderId
	{
		get
		{
			if ( mobileProductPickerFolderId == null )
			{
				mobileProductPickerFolderId = UserInfo.getUserId();
			}
			return mobileProductPickerFolderId;
		}
	}
	
	public static Document generateImageDocument( String documentName, Blob documentBody )
	{
		Document mDocument = new Document();
		mDocument.Body = documentBody;
		mDocument.ContentType = 'image/png';
		mDocument.FolderId = mobileProductPickerFolderId;
		mDocument.IsPublic = false;
		mDocument.Name = documentName;
		mDocument.Type = 'png';
		return mDocument;
	}
	
	public static Document generateTextDocument( String documentName, Blob documentBody )
	{
		Document mDocument = new Document();
		mDocument.Body = documentBody;
		mDocument.ContentType = 'text/plain';
		mDocument.FolderId = mobileProductPickerFolderId;
		mDocument.IsPublic = false;
		mDocument.Name = documentName;
		mDocument.Type = 'txt';
		return mDocument;
	}
	
	public static Document generatePDFDocument( String documentName, Blob documentBody )
	{
		Document mDocument = new Document();
		mDocument.Body = documentBody;
		mDocument.ContentType = 'application/pdf';
		mDocument.FolderId = mobileProductPickerFolderId;
		mDocument.IsPublic = false;
		mDocument.Name = documentName;
		mDocument.Type = 'pdf';
		return mDocument;
	}
}