# Review Dashboard — Firestore Schema

The `review_dashboard/` web app (dermatologist-facing review tool for the
healthy-skin data flywheel) reads and writes exactly one collection and one
settings document in the **same Firebase project** the mobile app uses
(`dermaafrica-b2cd9`). No second backend, no new project.

## Collection: `healthy_skin_contributions`

```
{
  id: string                      // Firestore document id
  imageUrl: string                // Direct, public Cloudinary URL (secure_url) —
                                   // loadable as-is by an <img> tag, no resolution
                                   // step needed. NOT a Firebase Storage path.
  fitzpatrickType: "I"|"II"|"III"|"IV"|"V"|"VI"
  bodyRegion: "forearm"|"upper_arm"|"lower_leg"|"torso"|"face"|"hand"|"neck"
  contributorId: string           // volunteer/staff identifier, not a real name
  facility: string                // partner hospital / site
  submittedAt: timestamp
  status: "pending" | "approved" | "rejected"
  plausibilityScore: 1 | 2 | 3 | null
  reviewNote: string | null
  reviewedBy: string | null       // reviewer's email, from the allow-list
  reviewedAt: timestamp | null
}
```

**Why Cloudinary, not Firebase Storage:** Firebase Storage now requires the
project to be on the Blaze (pay-as-you-go) billing plan even to use its
free-tier quota. Rather than add billing to the shared project, the mobile
app (`ContributionUploadService`) uploads the photo bytes directly to
Cloudinary via an unsigned upload preset and stores the resulting
`secure_url` in `imageUrl`. See
`flutter_app/lib/core/constants/cloudinary_config.dart` for the real
trade-off this implies (no per-user upload check, unlike the Storage rules
this replaced — mitigated via the upload preset's own restrictions, not
app-side secrecy).

**The only mutation in the whole tool** is a status-field update on an
existing document: `status`, `plausibilityScore`, `reviewNote`, `reviewedBy`,
`reviewedAt`. Nothing ever deletes a document or touches the Cloudinary image
it points at — that's the full audit trail the ethics chapter's
data-provenance commitment depends on.

## Settings document: `settings/coverage`

```
{ targetPerCell: number }   // default 8 if the document doesn't exist yet
```

The minimum *approved* count per (Fitzpatrick type × body region) cell before
that cell counts as "covered" in the coverage matrix. Configurable, not
hardcoded — see `review_dashboard/src/lib/data/repo.ts`
(`DEFAULT_COVERAGE_TARGET`).

## Data layer

`review_dashboard/src/lib/data/repo.ts` defines the `ContributionsRepo` /
`CoverageTargetRepo` interfaces, implemented by
`review_dashboard/src/lib/data/firestoreRepo.ts` — the dashboard always talks
to the real Firebase project (no mock mode; that was removed once the mobile
upload flow existed for real).

## ⚠️ Before deploying `firestore.rules`

`review_dashboard/firestore.rules` only defines access for the collections
this tool introduces (`healthy_skin_contributions`, `settings/coverage`,
`reviewers/{uid}`). The mobile app's existing rules for `chws/{uid}` are not
captured anywhere in this repo. **Pull the current production rules from the
Firebase console and merge** rather than deploying this file directly — see
the warning comment at the top of the file.

## Mobile-side contribution flow

Exists and is live: Home screen → "Contribute Healthy Skin Photo" →
`ContributionMetadataScreen` (Fitzpatrick + body region) →
`ContributionCameraScreen` (capture) → local SQLite queue
(`healthy_skin_contributions` table, offline-first) →
`ContributionUploadService` uploads to Cloudinary + writes this Firestore
document once connectivity allows, retrying automatically.
