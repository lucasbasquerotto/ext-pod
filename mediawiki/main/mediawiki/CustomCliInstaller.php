<?php
/**
 * Core installer command line interface.
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
 * @ingroup Installer
 */

/**
 * Class for the custom installer command line interface.
 *
 * @ingroup Installer
 * @since 1.17
 */
class CustomCliInstaller extends CliInstaller {

	/**
	 * @param string $siteName
	 * @param string|null $admin
	 * @param array $options
	 * @throws InstallException
	 */
	public function __construct( $siteName, $admin = null, array $options = [] ) {
		global $wgContLang;

		parent::__construct( $siteName, $admin, $options );
	}

	/**
	 * Main entry point.
	 * @return Status
	 */
	public function execute() {
		// If APC is available, use that as the MainCacheType, instead of nothing.
		// This is hacky and should be consolidated with WebInstallerOptions.
		// This is here instead of in __construct(), because it should run run after
		// doEnvironmentChecks(), which populates '_Caches'.
		if ( count( $this->getVar( '_Caches' ) ) ) {
			// We detected a CACHE_ACCEL implementation, use it.
			$this->setVar( '_MainCacheType', 'accel' );
		}

		$result = $this->performInstallation(
			[ $this, 'startStage' ],
			[ $this, 'endStage' ]
		);
		// PerformInstallation bails on a fatal, so make sure the last item
		// completed before giving 'next.' Likewise, only provide back on failure
		$lastStepStatus = end( $result );
		if ( $lastStepStatus->isOK() ) {
			return Status::newGood();
		} else {
			return $lastStepStatus;
		}
	}
}