define make-target
$(1):
	mkdir -p $$@

$(1)/$(1).opus: $(1).yaml $(1)
	$$(eval video = $$(shell yq r $$< video))
	$$(eval offset = $$(shell yq r $$< offset))
	$$(eval duration = $$(shell yq r $$< duration | awk '{print $$$$0 + 1}'))
	$$(eval all = $(1)/$(1).audio)
	youtube-dl --extract-audio --audio-quality 0 --audio-format opus \
		--no-part --output $$(all) \
		--postprocessor-args "-ss $$(offset) -t $$(duration)" \
		$$(video)
	rm -f $$(all)

$(1)/$(1).mkv: $(1).yaml $(1)
	$$(eval video = $$(shell yq r $$< video))
	$$(eval offset = $$(shell yq r $$< offset))
	$$(eval duration = $$(shell yq r $$< duration | awk '{print $$$$0 + 1}'))
	$$(eval all = $(1)/$(1).video)
	youtube-dl --format bestvideo+bestaudio --merge-output-format mkv \
		--no-part --output $$(all) \
		$$(video)
	ffmpeg -i $$(all).mkv -ss $$(offset) -t $$(duration) $$@
	rm -f $$(all).mkv

$(1)/$(1).gif: $(1)/$(1).mkv
	$$(eval palette = $(1)/$(1).palette.png)
	$$(eval filters = "fps=24,scale=640:-1:flags=lanczos")
	ffmpeg -i $$< -filter:v "$$(filters),palettegen" -y $$(palette)
	ffmpeg -i $$< -i $$(palette) -ignore_loop 0 \
		-filter_complex "$$(filters) [x]; [x][1:v] paletteuse" -y $@
endef

define get-audio
	$(1)/$(1).opus
endef
define get-video
	$(1)/$(1).mkv
endef
define get-gif
	$(1)/$(1).gif
endef

prerequisites: Brewfile
	brew update >/dev/null
	brew bundle check || brew bundle

TARGETS := $(wildcard *.yaml)
$(foreach t,$(TARGETS),$(eval $(call make-target,$(strip $(basename $(t) .yaml)))))

.PHONY = audio video gif all
.DEFAULT_GOAL := all
audio: $(foreach t,$(TARGETS),$(call get-audio,$(strip $(basename $(t) .yaml))))
video: $(foreach t,$(TARGETS),$(call get-video,$(strip $(basename $(t) .yaml))))
gif: $(foreach t,$(TARGETS),$(call get-gif,$(strip $(basename $(t) .yaml))))
all: audio video gif
