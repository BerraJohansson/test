<%@ Page Language="C#" ContentType="text/html" ResponseEncoding="UTF-8" Debug="true" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<%@Import Namespace="System.Net"%>
<%@Import Namespace="System.IO"%>
<%@Import Namespace="System.Runtime.Serialization.Json"%>
<%@Import Namespace="System.Runtime.Serialization"%>
<script language="c#" runat="server">

//global
string apiUrl = "http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0001/BE0001D/BE0001T05AR";

//Request
[DataContract]
class response
{
    [DataMember]
	internal string format;
}
[DataContract]
class selection
{
    [DataMember]
	internal string filter;
    [DataMember]
	internal List<string> values;
}
[DataContract]
class query
{
    [DataMember]
	internal string code;
    [DataMember]
	internal selection selection;
}
[DataContract]
class APIRequest
{
    [DataMember]
	internal List<query> query;
    [DataMember]
	internal response response;
}

//Response with metadata
[DataContract]
class variables
{
    [DataMember]
	internal string code;
    [DataMember]
	internal string text;
    [DataMember]
	internal List<string> values;
    [DataMember]
	internal List<string> valueTexts;
    [DataMember]
	internal string time;
}
[DataContract]
class APIResponseMetaData
{
    [DataMember]
	internal string title;
    [DataMember]
	internal List<variables> variables;
}

//Response with data
[DataContract]
class columns
{
    [DataMember]
	internal string code;
    [DataMember]
	internal string text;
    [DataMember]
	internal string type;
}
[DataContract]
class comments
{
}
[DataContract]
class data
{
    [DataMember]
	internal List<string> key;
    [DataMember]
	internal List<string> values;
}
[DataContract]
class metadata
{
    [DataMember]
	internal string infofile;
    [DataMember]
	internal string updated;
    [DataMember]
	internal string label;
    [DataMember]
	internal string source;
}
[DataContract]
class APIResponseData
{
    [DataMember]
	internal List<columns> columns;
    [DataMember]
	internal List<comments> comments;
    [DataMember]
	internal List<data> data;
    [DataMember]
	internal List<metadata> metadata;
}

private void Page_Load(object sender, EventArgs e)
{
	if (!Page.IsPostBack)
	{	
		//Fetch meta data from SCB
		APIResponseMetaData response = APIMetaData();
	
		if (response != null)
		{
			//Set header for page
			Header.Text = response.title;
			
			//Loop through all years from meta data and set droplist values
			for (int i = 0;i < response.variables[1].values.Count; i++)
				DropDownListType.Items.Add(new ListItem(response.variables[1].valueTexts[i], response.variables[1].values[i]));
	
			//Loop through all years from meta data and set droplist values
			for (int i = 0;i < response.variables[2].values.Count; i++)
				DropDownListYear.Items.Add(response.variables[2].values[i]);
		}
	}
}
APIRequest APIRequestData(string type, string filter, List<string> values, List<string> years)
{
	//Creat query request sent to SCB
	response Response = new response();
 	Response.format = "json";
	
	var Values1 = new List<string>();
	Values1 = values;	

	selection Selection1 = new selection();
	Selection1.filter = filter;
	Selection1.values = Values1;
	
	query Query1 = new query();
	Query1.code = "Tilltalsnamn";
	Query1.selection = Selection1;

	var Values2 = new List<string>();
	Values2.Add(type);
	
	selection Selection2 = new selection();
	Selection2.filter = "item";
	Selection2.values = Values2;
	
	query Query2 = new query();
	Query2.code = "ContentsCode";
	Query2.selection = Selection2;

	var Values3 = new List<string>();
	Values3 = years;	
		
	selection Selection3 = new selection();
	Selection3.filter = "item";
	Selection3.values = Values3;
	
	query Query3 = new query();
	Query3.code = "Tid";
	Query3.selection = Selection3;

	var Query = new List<query>();
	Query.Add(Query1);
	Query.Add(Query2);
	Query.Add(Query3);

	APIRequest apiRequest = new APIRequest();
	apiRequest.query = Query;
	apiRequest.response = Response;
	
	return apiRequest;
}
string trimName(string name)
{	
	if (Char.IsNumber(name,0) && !Char.IsNumber(name,1))
		return name.Substring(1);
	if (Char.IsNumber(name,0) && Char.IsNumber(name,1))
		return name.Substring(2);
	
	return name;
}
int adjustScale(string type, string filter)
{	
	int scale = 1;
		
	if (type == "BE0001AI")	
	{
		if (filter == "vs:Flickor10")	
			scale = 100;
		if (filter == "vs:Flickor100")	
			scale = 10;
		if (filter == "vs:Pojkar10")	
			scale = 100;
		if (filter == "vs:Pojkar100")	
			scale = 10;
	}	
	return scale;
}
string printTabelOneYear(APIResponseData responseData, string type, string filter, List<string> names, List<string> years, Dictionary<string,int> keys)
{
	var sortedDicts = from entry in keys orderby entry.Value descending select entry;

	string result = "<table><tr><th></th>";
	foreach (string year in years)
		result = result + "<th>" + year + "</th>" ;
	result = result + "</tr><tr>";
	
	int max = 0;
	foreach (var sortedDict in sortedDicts)
	{	
		if (sortedDict.Value != 0)
		{
 			result = result + "<th>" + trimName(sortedDict.Key.Split(',')[0]) + "</th>";
			foreach (string year in years)
			{
				result = result + "<td>" + sortedDict.Value + "<img src='gray.jpg' align='absmiddle'  alt=' ' name='Graf' width='" + (sortedDict.Value*adjustScale(type,filter)).ToString() + "' height='18'/></td>";
				
			}
			result = result + "</tr><tr>";
		}
	}
	result = result + "</tr></table>";
	
	return result;
}
string printTabelAllYear(APIResponseData responseData, string type, string filter,  List<string> names, List<string> years, Dictionary<string,int> keys)
{
	string result = "<table><tr><th></th>";
	foreach (string year in years)
		result = result + "<th>" + year + "</th>" ;
	result = result + "</tr><tr>";
	
	foreach (string name in names)
	{	
		result = result + "<th>" + trimName(name) + "</th>";
		foreach (string year in years)
			result = result + "<td>" + keys[name + "," + year].ToString() + "</td>";
		result = result + "</tr><tr>";
	}
	result = result + "</tr></table>";

	return result;
}
string printTabel(APIResponseData responseData, string type, string filter, List<string> names, List<string> years)
{	
	Dictionary<string,int> keys = new Dictionary<string, int>();
	for (int i = 0;i < responseData.data.Count; i++)
        keys[responseData.data[i].key[0] + "," + responseData.data[i].key[1]] = Int32.Parse(responseData.data[i].values[0].Replace("..","0"));
	
	string result = "";
	
	if (years.Count == 1)
		result = printTabelOneYear(responseData, type, filter, names, years, keys);
	else
		result = printTabelAllYear(responseData, type, filter, names, years, keys);
	return result;
}
string API(string type, string filter, string year)
{
	APIResponseMetaData response = APIMetaData();

	List<string> allNames = new List<string>();
	//Loop through all names from meta data
	for (int i = 0;i < response.variables[0].values.Count; i++)
		allNames.Add(response.variables[0].values[i]);

	List<string> names = null;
	if (filter == "vs:Flickor10")
	{
		names = allNames.Where(x => x.StartsWith("20")).ToList();
		names.Remove("20Linnéa");

	}
	if (filter == "vs:Flickor100")
	{
		names = allNames.Where(x => x.StartsWith("2") && !x.StartsWith("20")).ToList();
		names.Remove("2Linnéa");
		names.Remove("2Märta");
	}
	if (filter == "vs:Pojkar10")
	{
		names = allNames.Where(x => x.StartsWith("10")).ToList();
	}
	if (filter == "vs:Pojkar100")
	{
		names = allNames.Where(x => x.StartsWith("1") && !x.StartsWith("10")).ToList();
		names.Remove("1André");
		names.Remove("1Björn");
		names.Remove("1Måns");
	}

	List<string> years = new List<string>();
	//Loop through all years from meta data
	for (int i = 0;i < response.variables[2].values.Count; i++)
	{
		years.Add(response.variables[2].values[i]);
	}
					
	if (year != "-")
		years = years.Where(x => x.Contains(year)).ToList();
	
	string result = "";

	ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
	
	try
	{		
		HttpWebRequest myHttpWebRequest = (HttpWebRequest)WebRequest.Create(apiUrl);
 		myHttpWebRequest.Method = "POST";
 		myHttpWebRequest.Accept = "application/json";
				
		using (var streamWriter = new StreamWriter(myHttpWebRequest.GetRequestStream()))
		{
			DataContractJsonSerializer serRequest = new DataContractJsonSerializer(typeof(APIRequest));
		
	  		using (MemoryStream memoryStream = new MemoryStream())
    		{
        		serRequest.WriteObject(memoryStream, APIRequestData(type, filter, names, years));
        		streamWriter.Write(Encoding.Default.GetString(memoryStream.ToArray()));
    		}
				}

		// Get the associated response for the above request.
     	HttpWebResponse myHttpWebResponse = (HttpWebResponse)myHttpWebRequest.GetResponse();
  		using (var streamReader = new StreamReader(myHttpWebResponse.GetResponseStream()))
		{
			DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(APIResponseData));
			var responseData = (APIResponseData)ser.ReadObject(myHttpWebResponse.GetResponseStream());
			
			result = printTabel(responseData, type, filter, names, years);
		}
	}

	catch(Exception e)
	{
	    result = e.Message;
	}
	return result;
}
APIResponseMetaData APIMetaData()
{
	string result = "";
	
	try
	{
		// Create the request.
   		HttpWebRequest myHttpWebRequest = (HttpWebRequest)WebRequest.Create(apiUrl);
 		myHttpWebRequest.Method = "GET";
 		myHttpWebRequest.Accept = "application/json";
				
		// Get the associated response for the request.
     	HttpWebResponse myHttpWebResponse = (HttpWebResponse)myHttpWebRequest.GetResponse();
  		using (var streamReader = new StreamReader(myHttpWebResponse.GetResponseStream()))
		{
			DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(APIResponseMetaData));
			return (APIResponseMetaData)ser.ReadObject(myHttpWebResponse.GetResponseStream());
		}
	}
	catch(Exception e)
	{
	    return null;
	}
	return null;
}
public void DropDownListType__SelectedIndexChanged(object sender, EventArgs e)
{	
	if (DropDownListType.SelectedItem.Value != "-" && DropDownListDivision.SelectedItem.Value != "-")
		RequestResult.Text = API(DropDownListType.SelectedItem.Value, DropDownListDivision.SelectedItem.Value, DropDownListYear.SelectedItem.Value);
	else
		RequestResult.Text = "";
}
public void DropDownListDivision__SelectedIndexChanged(object sender, EventArgs e)
{	
	if (DropDownListType.SelectedItem.Value != "-" && DropDownListDivision.SelectedItem.Value != "-")
		RequestResult.Text = API(DropDownListType.SelectedItem.Value, DropDownListDivision.SelectedItem.Value, DropDownListYear.SelectedItem.Value);
	else
		RequestResult.Text = "";
}
public void DropDownListYear__SelectedIndexChanged(object sender, EventArgs e)
{	
	if (DropDownListType.SelectedItem.Value != "-" && DropDownListDivision.SelectedItem.Value != "-")
		RequestResult.Text = API(DropDownListType.SelectedItem.Value, DropDownListDivision.SelectedItem.Value, DropDownListYear.SelectedItem.Value);
}
</script>
<style>
body {
  font-family: Arial;
  padding: 30px;
}
.header {
  font-family: Arial;
  font-weight:bold;
  font-size: 20px;
}
th {
  font-family: Arial;
  font-weight:bold;
  text-align:left;
}
</style>
<head> 
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Namn</title>
</head>
<body>
	<form runat="server">
		<asp:Label CssClass="header" id="Header" runat="server"/>
		        
		<br />
		<br />
        
        <asp:Label CssClass="label" id="Division" Text="Tilltalsnamn" runat="server"/>
        <asp:DropDownList id="DropDownListDivision"
			onselectedindexchanged="DropDownListDivision__SelectedIndexChanged" 
			AutoPostBack="true"
			AppendDataBoundItems="true"
			runat="server">
			<asp:ListItem Value="-"> - </asp:ListItem>
			<asp:ListItem Value="vs:Flickor10"> Flicknamn topp 10 </asp:ListItem>
			<asp:ListItem Value="vs:Flickor100"> Flicknamn topp 100 </asp:ListItem>
			<asp:ListItem Value="vs:Pojkar10"> Pojknamn topp 10 </asp:ListItem>
			<asp:ListItem Value="vs:Pojkar100"> Pojknamn topp 100 </asp:ListItem>
		</asp:DropDownList>

		<asp:Label CssClass="label" id="Type" Text="Tabellinnehåll" runat="server"/>
		<asp:DropDownList id="DropDownListType"
			onselectedindexchanged="DropDownListType__SelectedIndexChanged" 
			AutoPostBack="true"
			AppendDataBoundItems="true"
			runat="server">
			<asp:ListItem Value="-"> - </asp:ListItem>
		</asp:DropDownList>

		<asp:Label CssClass="label" id="Year" Text="År" runat="server"/>
		<asp:DropDownList id="DropDownListYear"
			onselectedindexchanged="DropDownListYear__SelectedIndexChanged" 
			AutoPostBack="true"
			AppendDataBoundItems="true"
			runat="server">
			<asp:ListItem Value="-"> - </asp:ListItem>
		</asp:DropDownList>
		
		<br />
		<br />

        <asp:Label id="RequestResult" runat="server"/>
	</form>
</body>
</html>
