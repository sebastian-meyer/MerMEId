xquery version "1.0" encoding "UTF-8";

import module namespace loop="http://kb.dk/this/getlist" at "./main_loop.xqm";

declare namespace xl="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace ht="http://exist-db.org/xquery/httpclient";

declare namespace app="http://kb.dk/this/app";
declare namespace m="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=text/html"; 

declare variable $coll   := request:get-parameter("c",    "") cast as xs:string;
declare variable $query  := request:get-parameter("query","");
declare variable $page   := request:get-parameter("page", "1") cast as xs:integer;
declare variable $number :=
request:get-parameter("itemsPerPage","20")   cast as xs:integer;

declare variable $from     := ($page - 1) * $number + 1;
declare variable $to       :=  $from      + $number - 1;

declare variable $published_only := 
request:get-parameter("published_only","") cast as xs:string;

declare function app:format-reference(
  $doc as node(),
  $pos as xs:integer ) as node() {

    let $class :=
      if($pos mod 2 = 1) then 
	"odd"
      else
	"even"

	let $ref   := 
	<tr class="result {$class}">
	  <td nowrap="nowrap">
	    {$doc//m:workDesc/m:work/m:titleStmt/m:respStmt/m:persName[@role='composer']}
	  </td>
	  <td>{app:view-document-reference($doc)}</td>
	  <td nowrap="nowrap">{app:get-edition-and-number($doc)} </td>
	  <td class="tools">
	    <a target="_blank"
            title="View XML source" 
            href="/storage/dcm/{util:document-name($doc)}">
	      <img src="/editor/images/xml.gif" 
	      alt="view source" 
	      border="0"
              title="View source" />
	    </a>
	  </td>
	  <td class="tools">{app:edit-form-reference($doc)}</td>
	  <td class="tools">{app:get-publication-reference($doc)}</td>
	  <td class="tools">{app:delete-document-reference($doc)}</td>
	</tr>
	return $ref
  };

  declare function app:options() as node()*
  { 
  let $options:= 
    (
    <option value="">All documents</option>,
    <option value="any">Published</option>,
    <option value="pending">Modified</option>,
    <option value="unpublished">Unpublished</option>)

    return $options
  };


  declare function app:pass-as-hidden() as node()* {
    let $inputs :=
      (
      <input name="published_only" type="hidden" value="{$published_only}"   />,
      <input name="c"              type="hidden" value="{$coll}"   />,
      <input name="query"          type="hidden" value="{$query}"  />,
      <input name="page"           type="hidden" value="{$page}"   />,
      <input name="itemsPerPage"   type="hidden" value="{$number}" />)
      return $inputs
  };


  declare function app:pass-as-hidden-except(
    $field as xs:string,
    $value as xs:string) as node()* 
    {

      let $inputs:=
      for $input in app:pass-as-hidden()
      return
	if($input/@name ne $field) then
	  $input
	else
	  ()
	
	return $inputs
    };

    declare function app:get-publication-reference($doc as node() )  as node()* 
    {
      let $doc-name:=util:document-name($doc)
      let $color_style := 
	if(doc-available(concat("public/",$doc-name))) then
	  (let $public_hash:=util:hash(doc(concat("public/",$doc-name)),'md5')
	  let $dcm_hash:=util:hash($doc,'md5')
	  return
	    if($dcm_hash=$public_hash) then
	      "publishedIsGreen"
	    else
	      "pendingIsYellow")
            else
	      "unpublishedIsRed"

	      let $form:=
	      <form id="formsourcediv{$doc-name}"
	      action="/storage/list_files.xq" 
	      method="post" style="display:inline;">
	      
		<div id="sourcediv{$doc-name}"
 		style="display:inline;">
		
		  <input id="source{$doc-name}" 
		  type="hidden" 
		  value="publish" 
		  name="dcm/{$doc-name}" 
		  title="file name"/>

		  <label class="{$color_style}" for='checkbox{$doc-name}'>
		    <input id='checkbox{$doc-name}'
		    onclick="add_publish('sourcediv{$doc-name}',
		    'source{$doc-name}',
		    'checkbox{$doc-name}');" 
		    type="checkbox" 
		    name="button" 
		    value="" 
		    title="publish"/></label>

		</div>
	      </form>
	      return $form
    };

    declare function app:get-edition-and-number($doc as node() ) as xs:string* {

      let $c := 
	$doc//m:fileDesc/m:seriesStmt/m:identifier[@type="file_collection"][1]/string()
	return ($c,$doc//m:meiHead/m:workDesc/m:work[1]/m:identifier[@type=$c]/string())

    };

    declare function app:view-document-reference($doc as node()) as node() {
      (: it is assumed that we live in /storage :)
      let $ref := 
      <a  target="_blank"
      title="View" 
      href="/storage/present.xq?doc={util:document-name($doc)}">
	{$doc//m:workDesc/m:work[1]/m:titleStmt/m:title[string()][1]/string()}
      </a>
      return $ref
    };

    declare function app:edit-form-reference($doc as node()) as node() 
    {
      (: 
      Beware: Partly hard coded reference here!!!
      It still assumes that the document resides on the same host as this
      xq script but on port 80

      The old form is called edit_mei_form.xml the refactored one starts on
      edit-work-case.xml 
      :)

      let $form-id := util:document-name($doc)
      let $ref := 
      <form id="edit{$form-id}" 
      action="/orbeon/xforms-jsp/mei-form/" style="display:inline;" method="get">

	<input type="hidden"
        name="uri"
	value="http://{request:get-header('HOST')}/editor/forms/mei/edit-work-case.xml" />
	<input type="hidden"
 	name="doc"
	value="{util:document-name($doc)}" />
	<input type="image"
 	title="Edit" 
	src="/editor/images/edit.gif" 
	alt="Edit" />
	{app:pass-as-hidden()}
      </form>

      return $ref

    };

    declare function app:delete-document-reference($doc as node()) as node() 
    {
      let $form-id := util:document-name($doc)
      let $uri     := concat("/db/public/",util:document-name($doc))
      let $form := 
	if(doc-available($uri)) then
	<span>
	  <img src="/editor/images/remove_disabled.gif" alt="Remove (disabled)" title="Only unpublished files may be deleted"/>
	</span>
      else
      <form id="del{$form-id}" 
      action="http://{request:get-header('HOST')}/filter/delete/dcm/{util:document-name($doc)}"
      method="post" 
      style="display:inline;">
	{app:pass-as-hidden()}
	<input type="hidden" 
	name="file"
	value="{request:get-header('HOST')}/storage/dcm/{util:document-name($doc)}"
	title="file name"/>
	<input 
	onclick="{fn:concat('show_confirm(&quot;del',$form-id,'&quot;,&quot;',$doc//m:workDesc/m:work/m:titleStmt/m:title[string()]/string()[1],'&quot;);return false;')}" 
	type="image" 
	src="/editor/images/remove.gif"  
	name="button"
	value="delete"
	title="Delete"/>
      </form>
      return  $form
    };

    declare function app:list-title() 
    {
      let $title :=
	if(not($coll)) then
	  "All documents"
	else
	  ($coll, " documents")

	  return $title
    };

    declare function app:navigation( 
      $list as node()* ) as node()*
      {

	let $total := fn:count($list/m:meiHead)
	let $uri   := "/storage/list_files.xq" 

	let $collection := 
	  if(not($coll)) then
	    ""
	  else
	    if($coll="all") then
	      ""
	    else
	      fn:concat("&amp;c=",$coll)


        let $querypart :=
	  if(not($query)) then 
	    ""
	  else
	    fn:concat("&amp;query=",$query)

        let $status_part :=
	  fn:concat("&amp;published_only=",$published_only)

        let $perpage  := fn:concat("&amp;itemsPerPage=",$number)
	let $nextpage := ($page+1) cast as xs:string

	let $next     :=
	  if($from + $number <$total) then
	    (element a {
	      attribute rel   {"next"},
	      attribute title {"Go to next page"},
	      attribute style {"text-decoration: none;"},
	      attribute href {
		fn:string-join((
		  $uri,"?",
		  "page=",
		  $nextpage,
		  $perpage,
		  $collection,
		  $status_part,
		  $querypart),"")
	      },
	      element img {
		attribute src {"/editor/images/next.png"},
		attribute alt {"Next"},
		attribute border {"0"}
	      }
	    })
	  else
	    ("") 

	    let $prevpage := ($page - 1) cast as xs:string

	    let $previous :=
	      if($from - $number + 1 > 0) then
		(
		  element a {
		    attribute rel {"prev"},
		    attribute title {"Go to previous page"},
		    attribute style {"text-decoration: none;"},
		    attribute href {
       		      fn:string-join(
			($uri,"?","page=",$prevpage,$perpage,$collection,$querypart),"")},
			element img {
			  attribute src {"/editor/images/previous.png"},
			  attribute alt {"Previous"},
			  attribute border {"0"}
			}
		  })
		else
		  ("") 

		let $page_nav := for $p in 1 to fn:ceiling( $total div $number ) cast as xs:integer
		return 
		  (if(not($page = $p)) then
		  element a {
		    attribute title {"Go to page ",xs:string($p)},
		    attribute href {
       		      fn:string-join(
			($uri,"?",
			"page=",xs:string($p),
			$perpage,
			$collection,
			$status_part,
			$querypart),"")},
			($p)
		  }
		else 
		  element span {
		    attribute style {"color:#999;"},
		    ($p)
		  }
		)
		let $links := ( 
		  element div {
		    element strong {
		      "Found ",$total," files"
		    },
		    (". Display "),
		    (<form action="/storage/list_files.xq" style="display:inline;">
		    <select name="itemsPerPage" onchange="this.form.submit();return true;"> 
		      {(
			element option {attribute value {"10"},
			if($number=10) then 
			  attribute selected {"selected"}
			else
			  "",
			  "10 per page"},
			  element option {attribute value {"20"},
			  if($number=20) then 
			    attribute selected {"selected"}
			  else
			    "",
			    "20 per page"},
			    element option {attribute value {"50"},
			    if($number=50) then 
			      attribute selected {"selected"}
			    else
			      "",
			      "50 per page"},
			      element option {attribute value {"100"},
			      if($number=100) then 
				attribute selected {"selected"}
			      else
				"",
				"100 per page"},
				element option {attribute value {$total cast as xs:string},
				if($number=$total) then 
				  attribute selected {"selected"}
				else
				  "",
				  "all"}
		       )}
		    </select>
				  
		    <input type="hidden" name="published_only"  value="{$published_only}"/>
		    <input type="hidden" name="c"  value="{$coll}"/>
		    <input type="hidden" name="query" value="{$query}"/>
		    <input type="hidden" name="page" value="1" />
				  
		    </form>),
		    element p {
		      $previous,"&#160;",
		      $page_nav,
		      "&#160;", $next}
		  })
		  return $links

      };
      <html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	  <title>
	    {app:list-title()}
	  </title>
	  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
	  <link rel="styleSheet" 
	  href="/editor/style/list_style.css" 
	  type="text/css"/>
	  <link rel="styleSheet" 
	  href="/editor/style/xform_style.css" 
	  type="text/css"/>
	  
	  <script type="text/javascript" src="/editor/js/confirm.js">
	  //
	  </script>
	  
	  <script type="text/javascript" src="/editor/js/checkbox.js">
	  //
	  </script>
	  
	  <script type="text/javascript" src="/editor/js/publishing.js">
	  //
	  </script>

	</head>
	<body class="list_files">
	  <div class="list_header">
	    <div style="float:right;">
	      <a title="Add new file" href="#" class="addLink" 
	      onclick="location.href='/filter/new/dcm/'; return false;"><img 
	      src="/editor/images/new.gif" alt="New file" border="0" /></a>
	      &#160;
	      <a href="/editor/manual/" 
	      class="addLink"
	      target="_blank"><img 
	      src="/editor/images/help_light.png" 
	      title="Help - opens the manual in a new window or tab" 
	      alt="Help" 
	      border="0"/></a>
	    </div>
	    <img src="/editor/images/mermeid_30px_inv.png" 
            title="MerMEId - Metadata Editor and Repository for MEI Data" 
	    alt="MerMEId Logo"/>
	  </div>
	  <div class="filter_bar">
	    <table class="filter_block">
	      <tr>
		<td class="label">Filter by: &#160;</td>
		<td class="label">Publication status</td>
		<td class="label">Collection</td>
		<td class="label">Keywords</td>
	      </tr>
	      <tr>
		<td>&#160;</td>
		<td>
		  <form method="get" id="status-selection" action="/storage/list_files.xq" >
		    <select name="published_only" onchange="this.form.submit();">
		      {
  			for $alt in app:options()
			  let $option :=
			    if( $alt/@value eq $published_only ) then
		               <option value="{$alt/@value/text()}" 
			       selected="selected">
				 {$alt/text()}
			       </option>
			    else
			      $alt 
			  return $option
		      }
		      </select> 
		      {app:pass-as-hidden-except("published_only","")}
		    </form>
		</td>
		<td>
		
		  <select onchange="location.href=this.value; return false;">
		    {
            	      for $c in distinct-values(
            		collection("/db/dcm")//m:seriesStmt/m:identifier[@type="file_collection"]/string()[string-length(.) > 0])
            		let $querystring  := 
            		  if($query) then
            		    fn:string-join(
            		      ("c=",$c,
            		      "&amp;published_only=",$published_only,
            		      "&amp;itemsPerPage=",$number cast as xs:string,	
            		      "&amp;query=",
            		      fn:escape-uri($query,true())),
            		      ""
            		       )
            		     else
            		       concat("c=",$c,
            		       "&amp;published_only=",$published_only,
            		       "&amp;itemsPerPage="  ,$number cast as xs:string)
			       
            		       return
            			 if(not($coll=$c)) then 
            			 <option value="?{$querystring}">{$c}</option>
            	               else
            		       <option value="?{$querystring}" selected="selected">{$c}</option>
            }
            {
            
            	let $get-uri := 
            	if($query) then
            	fn:string-join(("?published_only=",$published_only,"&amp;query=",fn:escape-uri($query,true())),"")
            	else
            	concat("?c=&amp;published_only=",$published_only)
            
            	let $link := 
            	if($coll) then 
            	<option value="{$get-uri}">All collections</option>
            	else
            	<option value="{$get-uri}" selected="selected">All collections</option>
            	return $link
            }
            </select>
                    
          </td>
          <td>
            <form action="/storage/list_files.xq" method="get" class="search">
              <input name="query"  value='{request:get-parameter("query","")}'/>
              <input name="c"      value='{request:get-parameter("c","")}'    type='hidden' />
              <input name="published_only" value='{request:get-parameter("published_only","")}' type='hidden' />
              <input name="itemsPerPage"  value='{$number}' type='hidden' />
              <input type="submit" value="Search"               />
              <input type="submit" value="Clear" onclick="this.form.query.value='';this.form.submit();return true;"/>
              <a class="help">?<span class="comment">Search is case insensitive. 
              Search terms may be combined using boolean operators. Wildcards allowed. Some examples:<br/>
              <span class="help_table">
                <span class="help_example">
                  <span class="help_label">carl or nielsen</span>
                  <span class="help_value">Boolean OR (default)</span>
                </span>                        
                <span class="help_example">
                  <span class="help_label">carl and nielsen</span>
                  <span class="help_value">Boolean AND</span>
                </span>
                <span class="help_example">
                  <span class="help_label">"carl nielsen"</span>
                  <span class="help_value">Exact phrase</span>
                </span>
                <span class="help_example">
                  <span class="help_label">niels*</span>
                  <span class="help_value">Match any number of characters. Finds Niels, Nielsen and Nielsson<br/>
                    (use only at end of word)
                  </span>
                </span>
                <span class="help_example">
                  <span class="help_label">niels?n</span>
                  <span class="help_value">Match 1 character. Finds Nielsen and Nielson, but not Nielsson</span>
                </span>
              </span>
            </span>
              </a>
            </form>
          </td>
        </tr>
      </table>
    </div>
    {
      let $list := loop:getlist($published_only,$coll,$query)
      return
      <div class="files_list">
        <div class="nav_bar">
          {app:navigation($list)}
        </div>
           
        <table border='0' cellpadding='0' cellspacing='0' class='result_table'>
          <tr>
            <th>Composer</th>
            <th>Title</th>
            <th>Collection</th>
            <th class="tools">XML</th>
            <th class="tools">Edit</th>
            <th class="tools">	   
              <form method="post" id="publish_form" action="/storage/publish.xq" >
                <div id="publish">
                Publish 
                <img src="/editor/images/menu.png" 
                alt="Publishing menu" 
                onmouseover="document.getElementById('publish_menu').style.visibility='visible'"
                onmouseout="document.getElementById('publish_menu').style.visibility='hidden'"
                style="vertical-align: text-top;"/>
                <div class="popup" 
                     id="publish_menu" 
                     onmouseover="document.getElementById('publish_menu').style.visibility='visible'"
                     onmouseout="document.getElementById('publish_menu').style.visibility='hidden'">
               
                  <button 
                     type="submit" 
                     onclick="document.getElementById('publishingaction').value='publish';">
                    <img src="/editor/images/publish.png" alt="Publish"/>
                    Publish selected files
		  </button>
                  <br/>
                  <button 
                     type="submit"
                     onclick="document.getElementById('publishingaction').value='retract';">
                    <img src="/editor/images/unpublish.png" alt="Unpublish"/>
                    Unpublish selected files
		  </button>
                                   
               	  <input name="publishing_action" 
               	         type="hidden"
                         value="publish" 
                         id="publishingaction" />
                  {app:pass-as-hidden()}
                               
                  <hr/>
                               
                  <button type="button"
                          onclick="check_all();">
                    <img src="/editor/images/check_all.png" alt="Check all" title="Check all"/>
                    Select all files
		  </button>
                  <br/>
                  <button type="button"
                          onclick="un_check_all();">
                    <img src="/editor/images/uncheck_all.png" 
		         alt="Uncheck all" 
			 title="Uncheck all"/>
                         Unselect all files
		  </button>
                </div>
                </div>
              </form>
           	   
            </th>
            <th class="tools">Delete</th>
          </tr>
          {
            for $doc at $count in $list[position() = ($from to $to)]
            return app:format-reference($doc,$count)
          }
        </table>
      </div>
    }
    <div class="footer">
      <a href="http://www.kb.dk/dcm" title="DCM" 
      style="text-decoration:none;"><img 
           style="border: 0px; vertical-align:middle;" 
           alt="DCM Logo" 
           src="/editor/images/dcm_logo_small.png"/></a>
           2013 Danish Centre for Music Publication | The Royal Library, Copenhagen | <a name="www.kb.dk" id="www.kb.dk" href="http://www.kb.dk/dcm">www.kb.dk/dcm</a>
    </div>
  </body>
</html>
