//go:build tools

package tools

import (
	_ "git.glasklar.is/system-transparency/project/sthsm/cmd/mgmt"
	_ "git.glasklar.is/system-transparency/core/stauth"
	_ "system-transparency.org/stmgr"
	_ "system-transparency.org/stprov/cmd/stprov"
)
