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

## Settings in Community:

* you must put the URL of single sign on endpoint:
![screenshot](https://bitbucket.org/amazingacademy/community-sso-redirect-plugin/raw/master/screenshot.png)

* On login setting in you sso url label, you must put community.url/session/sso_sign:
![screenshot](https://bitbucket.org/amazingacademy/community-sso-redirect-plugin/raw/master/screenshot2.png)

## Settings for Campus amazing Login:
Inside login from campus.amazing.com

to get url and redirect :

```
header('Location:'. urldecode(base64_decode(urldecode($_GET["return"]))));
```
