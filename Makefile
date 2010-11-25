#use this to install my environment
VIM_DIR=${HOME}/.vim

all: editor shell_env vcs

editor: vim
	@echo "Setup editor environment....."

vim:
	@cp -r ${PWD}/_vim ${HOME}/.vim
	@cp ${PWD}/_vimrc ${HOME}/.vimrc
	@cp ${PWD}/_gvimrc ${HOME}/.gvimrc
	@echo "source ${HOME}/.vim/_vimrc" > ${HOME}/.vimrc
	@echo "source ${HOME}/.vim/_vimrc" > ${HOME}/.gvimrc

shell_env: bash zsh tmux screen
	@echo "Setup shell environment..."
	#@rm -r ${HOME}/.myENV
	@cp -r ${PWD}/_myENV ${HOME}/.myENV

bash:
	@cp ${PWD}/_bashrc ${HOME}/.bashrc

zsh:
	@cp ${PWD}/_zshrc ${HOME}/.zshrc

tmux:
	@cp ${PWD}/_tmux.conf ${HOME}/.tmux.conf

screen:
	@cp ${PWD}/_screenrc ${HOME}/.screenrc

vcs: git hg
	@echo "Setup Version Control environment...."

git:
	@cat _gitconfig > ${HOME}/.gitconfig
	
hg:
	@cat _hgrc > ${HOME}/.hgrc
