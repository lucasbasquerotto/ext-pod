<?php
# See includes/DefaultSettings.php for all configurable settings
# and their default values, but don't forget to make changes in _this_
# file, not there.
#
# Further documentation for configuration settings may be found at:
# https://www.mediawiki.org/wiki/Manual:Configuration_settings

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

## Uncomment this to disable output compression
# $wgDisableOutputCompression = true;

$wgSitename = "{{ params.sitename }}";
$wgMetaNamespace = "{{ params.meta_namespace }}";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs
## (like /w/index.php/Page_title to /wiki/Page_title) please see:
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath = "";

## The protocol and server name to use in fully-qualified URLs
$wgServer = "{{ params.server }}";

## The URL path to static resources (images, scripts, etc.)
$wgResourceBasePath = $wgScriptPath;

## The URL path to the logo.  Make sure you change this from the default,
## or else you'll overwrite your logo when you upgrade!
$wgLogo = "{{ params.logo }}";

## UPO means: this is also a user preference option

$wgEnableEmail = true;
$wgEnableUserEmail = true; # UPO

$wgEmergencyContact = "{{ params.emergency_contact }}";
$wgPasswordSender = "{{ params.password_sender }}";

$wgEnotifUserTalk = false; # UPO
$wgEnotifWatchlist = false; # UPO
$wgEmailAuthentication = true;

## Database settings
$wgDBtype = "mysql";
$wgDBserver = "{{ params.db_server }}";
$wgDBname = "{{ params.db_name }}";
$wgDBuser = "{{ params.db_user }}";
$wgDBpassword = "{{ params.db_password }}";

# MySQL specific settings
$wgDBprefix = "";

# MySQL table options to use during installation or update
$wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

## Shared memory settings

{###################################################################}
{% if params.use_memcached | bool %}

$wgMainCacheType = CACHE_MEMCACHED;
$wgParserCacheType = CACHE_MEMCACHED;
$wgMessageCacheType = CACHE_MEMCACHED;
$wgMemCachedServers = [ '{{ params.memcached_endpoint | urlsplit("netloc") }}' ];
$wgSessionCacheType = CACHE_MEMCACHED;

{% else %}

$wgCachePages = true;
$wgMainCacheType = CACHE_ACCEL;
$wgMemCachedServers = [];

{% endif %}
{###################################################################}

## To enable image uploads, make sure the 'images' directory
## is writable, then set this to true:
$wgEnableUploads = true;
$wgUseImageMagick = true;
$wgImageMagickConvertCommand = "/usr/bin/convert";

{###################################################################}
{% if (params.upload_path | default('')) != '' %}

$wgUploadPath = "{{ params.upload_path }}";

{% endif %}
{###################################################################}

# InstantCommons allows wiki to use images from https://commons.wikimedia.org
$wgUseInstantCommons = false;

# Periodically send a pingback to https://www.mediawiki.org/ with basic data
# about this MediaWiki instance. The Wikimedia Foundation shares this data
# with MediaWiki developers to help guide future development efforts.
$wgPingback = true;

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "C.UTF-8";

## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publicly accessible from the web.
#$wgCacheDirectory = "$IP/cache";

# Site language code, should be one of the list in ./languages/data/Names.php
$wgLanguageCode = "{{ params.lang }}";

$wgSecretKey = "{{ params.secret_key }}";

# Changing this will log out all existing sessions.
$wgAuthenticationTokenVersion = "{{ params.authentication_token_version }}";

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.
$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl = "";
$wgRightsText = "";
$wgRightsIcon = "";

# Path to the GNU diff3 utility. Used for conflict resolution.
$wgDiff3 = "/usr/bin/diff3";

## Default skin: you can change the default skin. Use the internal symbolic
## names, ie 'vector', 'monobook':
$wgDefaultSkin = "vector";

# Enabled skins.
# The following skins were automatically enabled:
wfLoadSkin( 'MonoBook' );
wfLoadSkin( 'Timeless' );
wfLoadSkin( 'Vector' );

# Enabled extensions. Most of the extensions are enabled by adding
# wfLoadExtensions('ExtensionName');
# to LocalSettings.php. Check specific extension documentation for more details.
# The following extensions were automatically enabled:
wfLoadExtension( 'Nuke' );
wfLoadExtension( 'WikiEditor' );
wfLoadExtension( 'VisualEditor' );

{###################################################################}
{% if params.use_s3_storage | bool %}

wfLoadExtension( 'AWS' );

$wgAWSRepoHashLevels = '2'; # Default 0
# 2 means that S3 objects will be named a/ab/Filename.png (same as when MediaWiki stores files in local directories)

$wgAWSRepoDeletedHashLevels = '3'; # Default 0
# 3 for naming a/ab/abc/Filename.png (same as when MediaWiki stores deleted files in local directories)

// Configure AWS credentials.
$wgAWSCredentials = [
	'key' => '{{ params.s3_key }}',
	'secret' => '{{ params.s3_secret }}',
	'token' => false
];

$wgAWSBucketName = '{{ params.s3_bucket }}';
$wgAWSRegion = '{{ params.s3_region | default("") }}';

{###################################################################}
{% if (params.s3_endpoint | default('')) != '' %}

$wgFileBackends['s3']['endpoint'] = '{{ params.s3_endpoint }}';

{###################################################################}
{% if (params.uploads_cdn_path | default('')) == '' %}

$wgAWSBucketDomain = '$1.{{ params.s3_endpoint | urlsplit("netloc") }}';

{% endif %}
{###################################################################}

{% endif %}
{###################################################################}

{###################################################################}
{% if (params.uploads_cdn_path | default('')) != '' %}

$wgAWSBucketDomain = '{{ params.uploads_cdn_path | urlsplit("netloc") }}';

{% endif %}
{###################################################################}

{###################################################################}
{% if (params.s3_path | default('')) != '' %}

$wgAWSBucketTopSubdirectory = '/{{ params.s3_path }}';

{% endif %}
{###################################################################}

{% endif %}
{###################################################################}

{###################################################################}
{% if not (params.disable_logs | bool) %}

$wgDBerrorLog = '/tmp/main/log/mediawiki/dberror.log';
$wgRateLimitLog = '/tmp/main/log/mediawiki/ratelimit.log';
$wgDebugLogGroups = array(
	'resourceloader' => '/tmp/main/log/mediawiki/resourceloader.log',
	'exception' => '/tmp/main/log/mediawiki/exception.log',
	'error' => '/tmp/main/log/mediawiki/error.log',
);

{% endif %}
{###################################################################}

{###################################################################}
{% if params.debug_logs | bool %}

$wgDebugLogFile = '/tmp/main/log/mediawiki/debug.log';

{% endif %}
{###################################################################}

{###################################################################}
{% if params.use_varnish | bool %}

$wgUseCdn = true;
$wgCdnServers = [];
$wgCdnServers[] = "varnish";

# workaround to fix https://phabricator.wikimedia.org/T235554
$wgDisableOutputCompression = true;

{% endif %}
{###################################################################}
