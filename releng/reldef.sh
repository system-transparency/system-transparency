# This file defines a release of System Transparency

declare -r ST_VERSION="R.2"

declare -r ST_SSHSIG_NAMESPACE="system-transparency.org:strel"
declare -r ST_SSHSIG_SIGNER_NAME="linus:YK5C-31"
declare -r ST_SSHSIG_ALLOWED_SIGNERS_FILE="allowed-signers"

declare -A artmap=([system-transparency:method]=git
		   [system-transparency:url]=https://git.glasklar.is/system-transparency/core/system-transparency
		   [system-transparency:version]=v0.2.0
		   [stboot:method]=git
		   [stboot:url]=https://git.glasklar.is/system-transparency/core/stboot
		   [stboot:version]=v0.2.0
		   [stmgr:method]=git
		   [stmgr:url]=https://git.glasklar.is/system-transparency/core/stmgr
		   [stmgr:version]=v0.2.1
		   [stprov:method]=git
		   [stprov:url]=https://git.glasklar.is/system-transparency/core/stprov
		   [stprov:version]=v0.1.1)

declare -r artefacts="system-transparency stboot stmgr stprov"
