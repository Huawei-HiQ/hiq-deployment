srpm:
	dnf install -y rpm-build
	rpmbuild -bs $(spec) -D "_topdir $(outdir)/rpmbuild" -D "_srcrpmdir _$(outdir)" --undefine="_disable_source_fetch"
