SHELL := /usr/bin/env bash
SCRIPTS := scripts

.PHONY: help new validate dev-link dev-unlink install info

help: ## 显示全部命令
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-18s %s\n", $$1, $$2}'

new: ## 创建新技能: make new name=<skill-name>
	@if [ -z "$(name)" ]; then \
		echo "Usage: make new name=<skill-name>"; \
		echo ""; \
		$(SCRIPTS)/new-skill.sh --help; \
		exit 1; \
	fi
	@$(SCRIPTS)/new-skill.sh "$(name)"

validate: ## 验证所有技能的 frontmatter 和命名规范
	@$(SCRIPTS)/validate.sh

dev-link: ## 符号链接 skills/ 到 ~/.claude/skills/（热更新）
	@$(SCRIPTS)/dev-link.sh

dev-unlink: ## 移除 ~/.claude/skills/ 中的符号链接
	@echo "Removing symlinks from ~/.claude/skills/..."
	@for link in ~/.claude/skills/*; do \
		if [ -L "$$link" ]; then \
			rm "$$link"; \
			echo "  Removed $$link"; \
		fi; \
	done; \
	echo "✔ Done"

install: ## 复制安装到 ~/.claude/skills/
	@$(SCRIPTS)/install.sh

info: ## 显示技能统计
	@count=0; \
	if [ -d "skills" ]; then \
		for d in skills/*/; do \
			[ -d "$$d" ] && count=$$((count + 1)); \
		done; \
	fi; \
	echo "cgartlab-skills"; \
	echo "  Skills: $$count"; \
	echo "  Location: $(shell pwd)"
