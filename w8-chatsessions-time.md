issue: #22795
pr: #22796
branch: fix/win-chatsessions-time-buckets
head: efd26556ff3e6fa7d4fd7f2da003846ddc753841
verified: traced frozen useMemo clock on origin/main e660746cf2d92f6eca498a26627ca16c64dd5d46; regression covers midnight-crossing rerender; CI with ci:full
