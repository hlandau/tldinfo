.PHONY: all clean tld-html-files tld-json-files

all: tlds.json.gz

clean:
	rm -rf tld-html tld-json tlds-alpha-by-domain.txt

tlds-alpha-by-domain.txt:
	wget "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"

db.html:
	wget -O db.html "https://www.iana.org/domains/root/db"

tld-html-files: $(patsubst %,tld-html/%.html,$(shell cat tlds-alpha-by-domain.txt | grep -v '#' | tr '\n' ' ' | tr '[:upper:]' '[:lower:]'))

tld-html/%.html:
	TLD="$(patsubst tld-html/%.html,%,$@)"; \
	mkdir -p tld-html tld-json; \
	wget -O "$@" "https://www.iana.org/domains/root/db/$$TLD.html"

tld-json-files: $(patsubst %,tld-json/%.json,$(shell cat tlds-alpha-by-domain.txt | grep -v '#' | tr '\n' ' ' | tr '[:upper:]' '[:lower:]'))

tld-json/%.json: tld-html/%.html
	./convert "$<" > "$@.tmp" && mv "$@.tmp" "$@"

tlds.json: tld-json-files
	jq -cs '{tlds:.}' tld-json/*.json > "$@"

tlds.json.gz: tlds.json
	gzip -kf "$<"

gh-pages: tlds.json.gz
	git branch -d gh-pages || true
	git checkout --orphan gh-pages
	git rm --cached -r .
	git add -f tlds.json tlds.json.gz index.xhtml
	git commit -m Auto
	git push -u origin gh-pages --force
	git checkout -f master
