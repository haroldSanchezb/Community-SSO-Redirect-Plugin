## To Install with Docker:

* Add in your app.yml:
```
hooks:
	after_code:
		- exec:
			cd: $home/plugins
			cmd:
				- mkdir -p plugins
				- git clone https://user:pass@bitbucket.org/amazingacademy/community-sso-redirect-plugin.git
```

* After:
```
./launcher rebuild app
```


## Get Redirect URL:
Inside login from campus.amazing.com

to get url and redirect :

```
header('Location:'. urldecode(base64_decode(urldecode($_GET["return"]))));
```
