# /*
#  * Copyright (c) 2014, webvariants GmbH, http://www.webvariants.de
#  *
#  * This file is released under the terms of the MIT license. You can find the
#  * complete text in the attached LICENSE file or online at:
#  *
#  * http://www.opensource.org/licenses/mit-license.php
#  * 
#  * @author: Tino Rusch (tino.rusch@webvariants.de)
#  */

PROJECTNAME=susi

OS=linux
ARCH=amd64

DEPLOY_HOST=localhost
DEPLOY_USER=root
DEPLOY_TARGET=$(DEPLOY_USER)@$(DEPLOY_HOST):/
ADDITIONAL_SSH_PARAMERS=

UGLIFYJS=uglifyjs
UGLIFYCSS=uglifycss

BUILDNUM=`cat .buildnum`

SERVERFILES=$(shell find $(GOPATH)/src/github.com/trusch/ -name '*.go')
FRONTENDCONTROLLER=$(shell find  ./webassets/js/controller/ -type f)
FRONTENDVIEWS=$(shell find  ./webassets/js/views/ -type f)
FRONTENDLIBS=$(shell find  ./webassets/js/lib/ -type f)
BACKENCONTROLLER=$(shell find ./controller/ -type f)
LESSFILES=$(shell find ./webassets/less/ -type f)
HTMLFILES=$(shell find ./webassets/ -name "*.html")
JADEFILES=$(shell find ./templates/ -name "*.jade")

COMPILED_JADEFILES=$(subst .jade,.js,$(JADEFILES))

INSTALLED_SERVERFILES=build/susi/usr/bin/susi
INSTALLED_FRONTENDCONTROLLER=build/susi/usr/share/susi/webassets/js/controller.js
INSTALLED_FRONTENDVIEWS=build/susi/usr/share/susi/webassets/js/views.js
INSTALLED_FRONTENDLIBS=build/susi/usr/share/susi/webassets/js/lib.js
INSTALLED_BACKENCONTROLLER=build/susi/usr/share/susi/controller/js/controller.js
INSTALLED_CSSFILES=build/susi/usr/share/susi/webassets/css/main.css
INSTALLED_HTMLFILES=$(subst ./webassets/,build/susi/usr/share/susi/webassets/,$(HTMLFILES))
INSTALLED_TEMPLATES=build/susi/usr/share/susi/webassets/js/templates.js

############
# Default target
############
default: prepare_package

############
# Build a fresh susi binary and copy webassets and controller into package tree
############
$(INSTALLED_SERVERFILES): $(SERVERFILES)
	GOOS=$(OS) GOARCH=$(ARCH) go build -x -o build/susi/usr/bin/susi github.com/trusch/susi
$(INSTALLED_FRONTENDCONTROLLER): $(FRONTENDCONTROLLER)
	mkdir -p $(shell dirname $@)
	$(UGLIFYJS) $(FRONTENDCONTROLLER) > $@
$(INSTALLED_FRONTENDVIEWS): $(FRONTENDVIEWS)
	mkdir -p $(shell dirname $@)
	$(UGLIFYJS) $(FRONTENDVIEWS) > $@
$(INSTALLED_FRONTENDLIBS): $(FRONTENDLIBS)
	mkdir -p $(shell dirname $@)
	$(UGLIFYJS) $(FRONTENDLIBS) > $@
$(INSTALLED_BACKENCONTROLLER): $(BACKENCONTROLLER)
	mkdir -p $(shell dirname $@)
	cat $(BACKENCONTROLLER) > $@
$(INSTALLED_CSSFILES): $(LESSFILES)
	mkdir -p $(shell dirname $@)
	lessc webassets/less/app.less | $(UGLIFYCSS) > $@ 
build/susi/usr/share/susi/webassets/%: ./webassets/%
	cp $< $@

############
# Prepare and build a debian package
############
prepare_package: $(INSTALLED_SERVERFILES) $(INSTALLED_TEMPLATES) $(INSTALLED_BACKENCONTROLLER) $(INSTALLED_FRONTENDLIBS) $(INSTALLED_FRONTENDVIEWS) $(INSTALLED_FRONTENDCONTROLLER) $(INSTALLED_CSSFILES) $(INSTALLED_HTMLFILES)
package: prepare_package update-buildnum
	bash -c "cd build && dpkg -b susi $(PROJECTNAME)-$(OS)-$(ARCH)-$(BUILDNUM).deb"

############
# Deploy to target host
############
deploy: build_package restart
build_package: prepare_package
	bash -c "rsync -e 'ssh $(ADDITIONAL_SSH_PARAMERS)' -avz build/susi/etc build/susi/usr $(DEPLOY_TARGET)"
restart:
	ssh $(ADDITIONAL_SSH_PARAMERS) $(DEPLOY_USER)@$(DEPLOY_HOST) "chmod +x /etc/init.d/susi && service susi restart"

############
# Version controlling. Update version and write into build/DEBIAN/control
############
update-buildnum: .buildnum
	bash -c "echo $(BUILDNUM) + 0.01 | bc -l| sed 's/^\./0./' > .buildnum"	
	bash -c 'sed -i s/"Version: [0-9\.]*"/"Version: $(BUILDNUM)"/ build/susi/DEBIAN/control'
.buildnum:
	echo 0.00 > .buildnum

############
# Cleanup build directory
############
clean:
	-rm -rf ./build/susi/usr/bin/*
	-rm -rf ./build/susi/usr/share/susi/*
	-rm -rf ./dev/cert.pem ./dev/key.pem
	-rm -rf $(COMPILED_JADEFILES)

############
# Compile jade file
############
include dev/rules.mk
gen_jade_rules: $(JADEFILES)
	bash dev/gen_jade_rules.sh > dev/rules.mk
./templates/%.js: ./templates/%.jade
	@jade -cD $<
./templates/templates.js: $(COMPILED_JADEFILES)
	@echo "var JST = JST || {};" > ./templates/templates.js
	@for filename in $(COMPILED_JADEFILES); do \
		name=$$(dirname $$(echo $$filename|cut -d/ -f2,3,4,5)); \
		name=$$name/$$(basename $$filename .js); \
		echo "JST['$$name']=" >> ./templates/templates.js; \
		cat $$filename >> ./templates/templates.js; \
		echo ";" >> ./templates/templates.js; \
	done
$(INSTALLED_TEMPLATES): ./templates/templates.js
	mkdir -p $(shell dirname $@)
	$(UGLIFYJS) ./templates/templates.js > $(INSTALLED_TEMPLATES)


############
# Run the susi server code tests
############
test: 
	 go test -cover github.com/trusch/susi/...
