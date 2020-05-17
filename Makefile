define make-target
$(1):
	mkdir -p $$@

$(1)/$(1).opus:
	$$(eval video = $$(shell yq r $(1).yaml video))
	$$(eval offset = $$(shell yq r $(1).yaml offset))
	$$(eval duration = $$(shell yq r $(1).yaml duration | awk '{print $$$$0 + 1}'))
	$$(eval all = $(1)/$(1).audio)
	youtube-dl --extract-audio --audio-quality 0 --audio-format opus \
		--no-part --output $$(all).audio \
		$$(video)
	ffmpeg -i $$(all).opus -ss $$(offset) -t $$(duration) $$@
	rm -f $$(all).opus

$(1)/$(1).mkv:
	$$(eval video = $$(shell yq r $(1).yaml video))
	$$(eval offset = $$(shell yq r $(1).yaml offset))
	$$(eval duration = $$(shell yq r $(1).yaml duration | awk '{print $$$$0 + 1}'))
	$$(eval all = $(1)/$(1).video)
	youtube-dl --format bestvideo+bestaudio --merge-output-format mkv \
		--no-part --output $$(all) \
		$$(video)
	ffmpeg -i $$(all).mkv -ss $$(offset) -t $$(duration) $$@
	rm -f $$(all).mkv

$(1)/$(1).gif: $(1)/$(1).mkv
	$$(eval palette = $(1)/$(1).palette.png)
	$$(eval filters = fps=24,scale=640:-1:flags=lanczos)
	ffmpeg -i $$< -filter:v "$$(filters),palettegen" -y $$(palette)
	ffmpeg -i $$< -i $$(palette) -ignore_loop 0 \
		-filter_complex "$$(filters) [x]; [x][1:v] paletteuse" -y $$@
endef

define get-target
	$(1)/$(1).$(2)
endef

.PHONY: prerequisites
prerequisites: Brewfile
	brew update >/dev/null
	brew bundle check || brew bundle

TARGETS := $(wildcard *.yaml)
$(foreach t,$(TARGETS),$(eval $(call make-target,$(strip $(basename $(t) .yaml)))))

.PHONY = opus mkv gif all
.DEFAULT_GOAL := all
opus: $(foreach t,$(TARGETS),$(call get-target,$(strip $(basename $(t) .yaml)),opus))
mkv: $(foreach t,$(TARGETS),$(call get-target,$(strip $(basename $(t) .yaml)),mkv))
gif: $(foreach t,$(TARGETS),$(call get-target,$(strip $(basename $(t) .yaml)),gif))
all: opus mkv gif
