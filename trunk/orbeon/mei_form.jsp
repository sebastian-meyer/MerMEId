<%@page contentType="text/html;charset=UTF-8"%>
<%@page import="java.io.*"%>
<%@page import="org.apache.log4j.*"%>
<%
response.setContentType("text/xml");
request.setCharacterEncoding("UTF-8");

java.lang.Long start = System.currentTimeMillis();
Logger logger = Logger.getLogger("mei_form.jsp");

org.apache.commons.httpclient.HttpClient httpClient = 
    new org.apache.commons.httpclient.HttpClient();

String pathInfo    = request.getPathInfo(); 
String uri         = request.getParameter("uri");
String queryString = request.getQueryString();
String newRequest  = queryString;
httpClient.getHttpConnectionManager().getParams().setConnectionTimeout(5000);

//if(logger.isInfoEnabled()){ 
logger.info("Sending request: " + uri); 
//}

//create a method object
org.apache.commons.httpclient.HttpMethod method = 
    new org.apache.commons.httpclient.methods.GetMethod(uri);

method.setFollowRedirects(true);
httpClient.executeMethod(method);

org.apache.commons.httpclient.Header[] responseHeaders = method.getResponseHeaders();

int status = method.getStatusLine().getStatusCode();
//if(logger.isInfoEnabled()) {
        logger.debug("response status:\t" + 
		status + 
	" (" + method.getStatusLine().toString()  + ")"); 
//}

for(int i=0;i<responseHeaders.length;i++) {
    if(logger.isInfoEnabled()) {
	logger.info("response:\t" + responseHeaders[i].toExternalForm()); 
    }
}
        
java.io.InputStream in  = method.getResponseBodyAsStream();

org.w3c.dom.Document form = null;
javax.xml.parsers.DocumentBuilder dBuilder = null;

javax.xml.parsers.DocumentBuilderFactory dfactory  =
    javax.xml.parsers.DocumentBuilderFactory.newInstance();

//java.io.PrintWriter out = response.getPrintWriter();

try {
    dfactory.setNamespaceAware(true);
    dfactory.setXIncludeAware(true);
    dBuilder = dfactory.newDocumentBuilder();
    form = dBuilder.parse(in);
    String formAsString = serialize(form);
    out.println(formAsString);
} catch (javax.xml.parsers.ParserConfigurationException parserPrblm) {
    logger.error(parserPrblm.getMessage());
} catch (org.xml.sax.SAXException xmlPrblm) {
    logger.error(xmlPrblm.getMessage());
}

java.lang.Long completed = System.currentTimeMillis() - start;
      
if(logger.isInfoEnabled()){ 
    logger.info(".. work done in " + completed + " ms"); 
}

in.close();



%>



<%!

String serialize(org.w3c.dom.Document doc) {
    Logger logger = Logger.getLogger("mei_form.jsp");
    try {
	org.w3c.dom.bootstrap.DOMImplementationRegistry registry =
	    org.w3c.dom.bootstrap.DOMImplementationRegistry.newInstance();

	org.w3c.dom.ls.DOMImplementationLS impl =
	    (org.w3c.dom.ls.DOMImplementationLS) registry.getDOMImplementation("LS");

	org.w3c.dom.ls.LSSerializer serializer = impl.createLSSerializer();
	return serializer.writeToString(doc);

    } catch (java.lang.ClassNotFoundException classNotFound) {
	logger.fatal(classNotFound.getMessage());
    } catch (java.lang.InstantiationException instantiationPrblm) {
	logger.fatal(instantiationPrblm.getMessage());
    } catch (java.lang.IllegalAccessException accessPrblm) {
	logger.fatal(accessPrblm.getMessage());
    }
    return "";
  }


%>