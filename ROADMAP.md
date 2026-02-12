# Project Roadmap

## Future Work

- [ ] **macOS Compatibility**
  - Update `.bashrc` to handle BSD/macOS specific commands (e.g., `sysctl -n hw.ncpu` vs `nproc`).
  - Replace `free -h` with `vm_stat` or similar for macOS memory checks.
  - Handle differences in `ls` coloring (BSD `ls -G` vs GNU `ls --color`).
  - Add support for standard Homebrew paths (`/usr/local/bin`, `/opt/homebrew/bin`).
  - Ensure `install.sh` logic works across both platforms.
  - Implement secure configuration sync for non-secret dotfiles, ensuring secrets remain local, excluded by `.gitignore`, and protected both at rest and in transit.
