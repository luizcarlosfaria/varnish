#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "your-web-server-Ip-or-Name-or-Address";
    .port = "80";
    
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
    .max_connections = 800;
}

    

sub vcl_recv {
	set req.http.host = "www.some-address.com.br";  
    
	#############################################
	# Purge Rules 
    #if (req.method == "PURGEALL") {
	#	# Wildcard, per-domain purging
	#	purge("req.http.host == " req.http.host " && req.url ~ " req.url "$"); 
	#	error 200 "Purged.";
    #}
    
    if (req.method == "PURGE") {    	
		return(purge);        
	}
    if (req.method == "BAN") {        
			ban("req.http.host ~ . ");
        	return(synth(200, "Ban added"));        
	}
	#############################################

	if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

	#Specific paths to ignore cache	
	# minha-conta, carrinho and finalizar-compra are special paths on commerce 
	if (req.url ~ "wp-admin|wp-login|minha-conta|carrinho|finalizar-compra|wc-api|xmlrpc|wordfence") {
        return (pass);
    }
	    
	#Removing cookies for static files
	if (req.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|pdf|png|rtf|swf|txt|woff|woff2|ttf)(\?.*)?$") {
    	set req.url = regsub(req.url, "\?.*$", "");
        unset req.http.Cookie;
        return (hash);
    }
   
   # Not cacheable by default
   if (req.http.Authorization) {    	
    	#return (pass);
  	}
    
    return (hash);
}

sub vcl_backend_response {

	if (bereq.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|pdf|png|rtf|swf|txt|woff|woff2|ttf)(\?.*)?$") {
    	set beresp.http.X-Cache-Rule = "Static Content";
		unset beresp.http.set-cookie;
		set beresp.ttl = 365d;
	}
	

	#In just case, i have the Nginx at top of stack, it will process with gzip responses
	set beresp.do_gzip = false; 

	if (bereq.url ~ "wp-admin|wp-login|minha-conta|carrinho|finalizar-compra|wc-api|xmlrpc|wordfence") { 
		set beresp.http.X-Cache-Rule = "Ignorado por regra";
		return (deliver);
	}
    
    
    set beresp.http.X-Cache-Rule = "Default";
    
    #unset beresp.http.set-cookie;
	#unset beresp.http.Expires;
	#unset beresp.http.Pragma;
	#unset beresp.http.Date;
	#unset beresp.http.Cache-Control;
    
    # Allow stale content, in case the backend goes down.
    # make Varnish keep all objects for 6 hours beyond their TTL
    set beresp.grace = 6h;
    set beresp.ttl = 1h;
    
	return (deliver);
}


# The data on which the hashing will take place
sub vcl_hash {
  # Called after vcl_recv to create a hash value for the request. This is used as a key
  # to look up the object in Varnish.

  hash_data(req.url);


  #if (req.http.host) {
  #  hash_data(req.http.host);
  #} else {
  #  hash_data(server.ip);
  #}

  # Cenários em que precisam de hash, não possuem cookies.
  # hash cookies for requests that have them
  if (req.http.Cookie) {
  	hash_data(req.http.Cookie);
  }
}

sub vcl_deliver {	
    unset resp.http.X-Varnish;
	unset resp.http.Via;
	unset resp.http.Age;
	unset resp.http.Server;
	unset resp.http.X-Powered-By;        

	if (obj.hits > 0) {
			set resp.http.X-Cache = "HIT";
	} else {
			set resp.http.X-Cache = "MISS";
	}
	set resp.http.X-Cache-Hits = obj.hits;
}


sub vcl_pipe {
     # Note that only the first request to the backend will have
     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
     # have it set for all requests, make sure to have:
     # set bereq.http.connection = "close";
     # here.  It is not set by default as it might break some broken web
     # applications, like IIS with NTLM authentication.
 
     set bereq.http.connection = "close";
     return (pipe);
}
