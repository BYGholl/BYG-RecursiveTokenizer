# GitHub upload instructions

This package is GitHub-ready. You do not need Git installed.

## Option A: Upload through GitHub website

1. Create a GitHub repository named `BYG-RecursiveTokenizer`.
2. Do not initialize it with a README, because this package already contains one.
3. Open the repository page in your browser.
4. Upload all files from the extracted `BYG_RecursiveTokenizer_v1.0.0` folder.
5. Commit with the message: `Release v1.0.0`.
6. Go to **Releases** -> **Draft a new release**.
7. Tag: `v1.0.0`.
8. Title: `BYG Recursive Tokenizer v1.0.0`.
9. Copy the contents of `GITHUB_RELEASE_BODY.md` into the release description.
10. Upload `BYG_RecursiveTokenizer_v1.0.0_GitHubReady.zip` as the release asset.
11. Publish the release.

## Option B: If Git is available later

```powershell
git init
git add .
git commit -m "Release v1.0.0"
git branch -M main
git remote add origin https://github.com/<your-user>/BYG-RecursiveTokenizer.git
git push -u origin main
git tag v1.0.0
git push origin v1.0.0
```

Then create the release from the GitHub website and attach the ZIP asset.
