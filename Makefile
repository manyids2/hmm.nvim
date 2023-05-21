.PHONY: install

define ANNOUNCE_INSTALL

	 = 🔥

  Setup first time with

  bash: export NVIM_APPNAME=nvim-apps/hmm.nvim; nvim
  fish: set -x NVIM_APPNAME nvim-apps/hmm.nvim; nvim

endef
export ANNOUNCE_INSTALL

define ANNOUNCE_DELETE

	  Delete?

	🔴 ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	🔴 ${XDG_DATA_HOME}/nvim-apps/hmm.nvim

endef
export ANNOUNCE_DELETE

define ANNOUNCE_RUN

   = 🔥

  Set NVIM_APPNAME ( currently:  ${NVIM_APPNAME} )

  bash: export NVIM_APPNAME=nvim-apps/hmm.nvim
  fish: set -x NVIM_APPNAME nvim-apps/hmm.nvim

  Go to examples folder, open hello.hmm file

  cd ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/examples; nvim hello.hmm

endef
export ANNOUNCE_RUN

define ANNOUNCE_DEV

   = 🔥

  Set NVIM_APPNAME ( currently:  ${NVIM_APPNAME} )

	Set dev dir as plugin in lua/bootstrap/plugins.lua

  bash: export NVIM_APPNAME=nvim-apps/hmm.nvim
  fish: set -x NVIM_APPNAME nvim-apps/hmm.nvim

  Go to examples folder, open hello.hmm file

  cd ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/examples; nvim hello.hmm

endef
export ANNOUNCE_DEV

install:
	git clone ./.git ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	# rm -r ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/lua/hmm
	@echo "$$ANNOUNCE_INSTALL"

dev:
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	cp -r ./ ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/lua/hmm
	@echo "$$ANNOUNCE_INSTALL"

run:
	@echo "$$ANNOUNCE_RUN"

clean:
	@echo "$$ANNOUNCE_DELETE"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	rm -rf ${XDG_DATA_HOME}/nvim-apps/hmm.nvim
