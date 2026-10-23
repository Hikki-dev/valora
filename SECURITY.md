# Security

## Reporting a problem

Please do not post a security problem in a public issue.

Open a [private security advisory](https://github.com/Hikki-dev/valora/security/advisories/new) on this repository instead. Say what you found, how to repeat it, and what it could allow. You will get a reply as soon as it can be read.

## What is protected

* Every table uses Row Level Security, so a person can only read and change their own rows.
* Google sign-in checks the ID token on the server. Passwords never reach Valora.
* Secret keys live in the server's secret store, not in the repository. The app only holds the publishable key, which is meant to be public.
* The website sends security headers, set in `vercel.json`.

## What to never share

Never post your Supabase service role key, your Google client secret, or a `.env.build` file. The publishable key is meant to be public, but a service role key is not.
