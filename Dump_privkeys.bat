::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Copyright (C) 2024 by Uwe Martens * www.namecoin.pro  * https://dotbit.app

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Batch Script for Exporting Private Keys of Names and UTXOs from Legacy BDB Wallets in Namecoin Core
:: ----------------------------------------------------------------------------------------------------
:: This Windows batch script automates the extraction of private keys for:
::   1. Unspent Transaction Outputs (UTXOs) using the 'listunspent' RPC command.
::   2. Names (assets) held in your wallet using the 'name_list' RPC command.
::
:: Known Issues:
:: ------------
:: - If two consecutive name updates to different addresses were made at the same block,
::   the 'name_list' RPC command will incorrectly output the first (invalid) private key.
::   In such cases:
::     - Manually export the correct private key using the 'dumpprivkey' RPC command.
::
:: Prerequisites:
:: --------------
:: - Ensure the wallet is unlocked if encrypted.
:: - Wait until all your wallet transactions have at least one confirmation to include all UTXOs.
:: - The script assumes you are using a legacy Berkeley DB (BDB) wallet in Namecoin Core.
:: - Make sure Namecoin Core is running and the RPC access is properly configured.
::
:: Notes:
:: ------
:: - The extracted private keys should be handled with extreme caution.
::   Never share or expose them, as they grant access to your funds and assets!
:: - This script does not modify wallet data; it only exports private keys for backup and migration purposes.
::
:: Output:
:: -------
:: - Private keys for names and UTXOs will be stored line by line in the 'privkeys.txt'.
:: - Rename or backup previous 'privkeys.txt' files.

:: DISCLAIMER:
:: ------------------
:: This script is provided "as is" without warranty of any kind, either expressed or implied. The author
:: disclaims any responsibility or liability for any loss of funds, assets or data, or for any damage
:: resulting from its use or misuse!

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@echo off
setlocal enabledelayedexpansion

set /a count=0
for /f "tokens=2" %%i in ('namecoin-cli listunspent ^| findstr /c:"address"') DO (
	set /a count+=1

	set address_utxo=%%i

	call set address_utxo=!address_utxo:"=!
	call set address_utxo=!address_utxo: =!
	call set address_utxo=!address_utxo:,=!

	for /f %%k in ('namecoin-cli dumpprivkey !address_utxo!') DO (
		set privkey=%%k
		echo !privkey!
		echo !privkey!>>privkeys.txt
	)
)

echo:
echo Number of UTXOs: %count%
echo:

ping -n 6 localhost > nul


namecoin-cli name_list>name_list.txt
set file_path=name_list.txt

set /a count=0
for /f "tokens=1,2" %%a in (%file_path%) DO (

	set token_a=%%a
	set token_b=%%b
	set token_a=!token_a:"=!
	set token_a=!token_a::=!

	if !token_a! EQU address (
		set address=!token_b:,=!
		set address=!address:"=!
	)

	if !token_a! EQU ismine (
		set mine=!token_b:,=!
	)

	if !token_a! EQU expires_in (
		set expires=!token_b:,=!

		if !expires! GEQ 1 (

			if !mine! EQU true (

				for /f %%k in ('namecoin-cli dumpprivkey !address!') DO (
					set privkey=%%k
					echo !privkey!
					echo !privkey!>>privkeys.txt
				)

				set /a count+=1
			)
		)
	)
)

echo:
echo Number of names: %count%
echo:
echo:

endlocal
pause
