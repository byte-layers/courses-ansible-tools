# Ansible — outils de gestion et d'exécution

Un cours pour situer et pratiquer les outils qui entourent Ansible, une fois le playbook écrit :
ansible-navigator et les *execution environments*, le mode pull avec `ansible-pull`, Semaphore UI,
puis le paysage AWX, Tower, Red Hat Ansible Automation Platform et Ascender. Il se suit dans VS Code
avec l'extension [byte_layers](https://marketplace.visualstudio.com/items?itemName=byte-layers.byte-layers)
(le cours est dans `.layers/`).

**Prérequis :** savoir lire et lancer un playbook Ansible ; un terminal bash (macOS, Linux, ou
WSL 2 sous Windows), Docker avec Compose v2, Python 3.12 ou plus récent, git.

Le dossier [`lab/`](lab/) contient les fichiers fournis et les solutions de référence. Tout ce que
vous écrivez va dans un dossier `atelier/`, ignoré par git. Les conteneurs créés par le cours
portent tous le préfixe `layers-`.

Contenu sous licence [CC BY-NC-SA 4.0](LICENSE).
