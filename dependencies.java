private class MyHttpHandler implements HttpHandler {    
2
  @Override    
3
  public void handle(HttpExchange httpExchange) throws IOException {
4
    String requestParamValue=null; 
5
    if("GET".equals(httpExchange.getRequestMethod())) { 
6
       requestParamValue = handleGetRequest(httpExchange);
7
     }else if("POST".equals(httpExchange)) { 
8
       requestParamValue = handlePostRequest(httpExchange);        
9
      }  
10
11
    handleResponse(httpExchange,requestParamValue); 
12
  }
13
14
   private String handleGetRequest(HttpExchange httpExchange) {
15
            return httpExchange.
16
                    getRequestURI()
17
                    .toString()
18
                    .split("\\?")[1]
19
                    .split("=")[1];
20
   }
21
22
   private void handleResponse(HttpExchange httpExchange, String requestParamValue)  throws  IOException {
23
            OutputStream outputStream = httpExchange.getResponseBody();
24
            StringBuilder htmlBuilder = new StringBuilder();
25
            
26
            htmlBuilder.append("<html>").
27
                    append("<body>").
28
                    append("<h1>").
29
                    append("Hello ")
30
                    .append(requestParamValue)
31
                    .append("</h1>")
32
                    .append("</body>")
33
                    .append("</html>");
34
35
            // encode HTML content 
36
            String htmlResponse = StringEscapeUtils.escapeHtml4(htmlBuilder.toString());
37
     
38
            // this line is a must
39
            httpExchange.sendResponseHeaders(200, htmlResponse.length());
40
41
            outputStream.write(htmlResponse.getBytes());
42
            outputStream.flush();
43
            outputStream.close();
44
        }
45
}
