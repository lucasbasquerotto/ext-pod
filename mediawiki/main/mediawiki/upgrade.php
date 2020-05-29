<?php
/**
 * CLI-based MediaWiki installation and configuration.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * http://www.gnu.org/copyleft/gpl.html
 *
 * @file
 * @ingroup Maintenance
 */

$base_path = '/var/www/html';

require_once __DIR__ . '/Maintenance.php';
require_once $base_path . '/includes/AutoLoader.php';
require_once $base_path . '/includes/installer/CustomCliInstaller.php';

define( 'MW_CONFIG_CALLBACK', 'Installer::overrideConfig' );
define( 'MEDIAWIKI_INSTALL', true );

/**
 * Maintenance script to upgrade MediaWiki
 *
 * Default values for the options are defined in DefaultSettings.php
 * (see the mapping in CliInstaller.php)
 *
 * @ingroup Maintenance
 */
class CommandLineUpgrader extends Maintenance {
	public function __construct() {
		parent::__construct();
		global $IP;

		$this->addDescription( "CLI-based MediaWiki installation and configuration.\n" .
			"Will install based on the settings at LocalSettings.php or update (if it's already installed)." );
	}

	public function execute() {
    	global $IP;

		$vars = Installer::getExistingLocalSettings();
		if ( !$vars ) {
			$status = Status::newFatal( "config-download-localsettings" );
			$this->showStatusMessage( $status );
			return $status;
		}

		$sitename = $vars['wgSitename'];
		$admin = $vars['wgDBuser'];
		$options = [
			'dbtype' => $vars['wgDBtype'],
			'dbserver' => $vars['wgDBserver'],
			'dbname' => $vars['wgDBname'],
			'dbuser' => $vars['wgDBuser'],
			'dbpass' => $vars['wgDBpassword'],
			'dbprefix' => $vars['wgDBprefix'],
			'dbtableoptions' => $vars['wgDBTableOptions'],
			'dbport' => $vars['wgDBport'],
			'dbschema' => $vars['wgDBmwschema'],
			'dbpath' => $vars['wgSQLiteDataDir'],
			'server' => $vars['wgServer'],
			'scriptpath' => $vars['wgScriptPath'],

			'lang' => $vars['wgLanguageCode'],
			'pass' => $vars['wgDBpassword'],
		];

		try {
			$installer = new CustomCliInstaller( $siteName, $admin, $options );
		} catch ( \MediaWiki\Installer\InstallException $e ) {
			$this->output( $e->getStatus()->getMessage( false, false, 'en' )->text() . "\n" );
			return false;
		}

		$status = $installer->doEnvironmentChecks();

		if ( $status->isGood() ) {
			$installer->showMessage( 'config-env-good' );
		} else {
			$installer->showStatusMessage( $status );
			return false;
		}
		
		$status = $installer->execute();

		if ( !$status->isGood() ) {
			$installer->showStatusMessage( $status );
			return false;
		}

		$installer->showMessage(
			'config-install-success',
			$installer->getVar( 'wgServer' ),
			$installer->getVar( 'wgScriptPath' )
		);
		
		return true;
	}
}

$maintClass = CommandLineUpgrader::class;

require_once RUN_MAINTENANCE_IF_MAIN;