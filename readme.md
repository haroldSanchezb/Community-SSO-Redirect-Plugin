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