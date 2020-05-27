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

require_once __DIR__ . '/Maintenance.php';

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
    
		try {
			$installer = InstallerOverrides::getCliInstaller( $siteName, $adminName, $this->mOptions );
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
		if ( !$envChecksOnly ) {
			$status = $installer->execute();
			if ( !$status->isGood() ) {
				$installer->showStatusMessage( $status );

				return false;
			}
			$installer->writeConfigurationFile( $this->getOption( 'confpath', $IP ) );
			$installer->showMessage(
				'config-install-success',
				$installer->getVar( 'wgServer' ),
				$installer->getVar( 'wgScriptPath' )
			);
		}
		return true;
	}

	private function setDbPassOption() {
		$dbpassfile = $this->getOption( 'dbpassfile' );
		if ( $dbpassfile !== null ) {
			if ( $this->getOption( 'dbpass' ) !== null ) {
				$this->error( 'WARNING: You have provided the options "dbpass" and "dbpassfile". '
					. 'The content of "dbpassfile" overrides "dbpass".' );
			}
			Wikimedia\suppressWarnings();
			$dbpass = file_get_contents( $dbpassfile ); // returns false on failure
			Wikimedia\restoreWarnings();
			if ( $dbpass === false ) {
				$this->fatalError( "Couldn't open $dbpassfile" );
			}
			$this->mOptions['dbpass'] = trim( $dbpass, "\r\n" );
		}
	}

	private function setPassOption() {
		$passfile = $this->getOption( 'passfile' );
		if ( $passfile !== null ) {
			if ( $this->getOption( 'pass' ) !== null ) {
				$this->error( 'WARNING: You have provided the options "pass" and "passfile". '
					. 'The content of "passfile" overrides "pass".' );
			}
			Wikimedia\suppressWarnings();
			$pass = file_get_contents( $passfile ); // returns false on failure
			Wikimedia\restoreWarnings();
			if ( $pass === false ) {
				$this->fatalError( "Couldn't open $passfile" );
			}
			$this->mOptions['pass'] = trim( $pass, "\r\n" );
		} elseif ( $this->getOption( 'pass' ) === null ) {
			$this->fatalError( 'You need to provide the option "pass" or "passfile"' );
		}
	}

	public function validateParamsAndArgs() {
		if ( !$this->hasOption( 'env-checks' ) ) {
			parent::validateParamsAndArgs();
		}
	}
}

$maintClass = CommandLineUpgrader::class;

require_once RUN_MAINTENANCE_IF_MAIN;