.PHONY: install

define ANNOUNCE_INSTALL

	 = 🔥

  Install to /usr/bin/hmm.nvim ?

endef
export ANNOUNCE_INSTALL

install:
	git clone ./.git ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	# rm -r ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/lua/hmm
	cd ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	chmod +x hmm.nvim
	@echo "$$ANNOUNCE_INSTALL"
	sudo cp hmm.nvim /usr/bin/hmm.nvim

define ANNOUNCE_DEV

   = 🔥

	Set dev dir as plugin in lua/bootstrap/plugins.lua

endef
export ANNOUNCE_DEV


dev:
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	cp -r ./ ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim/lua/hmm
	@echo "$$ANNOUNCE_DEV"

define ANNOUNCE_DELETE

	  Delete?

	🔴 ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	🔴 ${XDG_DATA_HOME}/nvim-apps/hmm.nvim

endef
export ANNOUNCE_DELETE

clean:
	@echo "$$ANNOUNCE_DELETE"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/hmm.nvim
	rm -rf ${XDG_DATA_HOME}/nvim-apps/hmm.nvim
