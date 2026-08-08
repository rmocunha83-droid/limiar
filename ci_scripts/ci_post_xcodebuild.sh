#!/bin/sh

set -eu

repository_path="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
google_service_info="${repository_path}/Limiar/GoogleService-Info.plist"
archive_path="${CI_ARCHIVE_PATH:-}"
derived_data_path="${CI_DERIVED_DATA_PATH:-}"

# O hook também pode rodar depois de ações que não produzem archive.
if [ -z "${archive_path}" ] || [ ! -d "${archive_path}/dSYMs" ]; then
    echo "Crashlytics: ação sem dSYMs de archive; nada para enviar."
    exit 0
fi

if [ ! -f "${google_service_info}" ]; then
    echo "Crashlytics: GoogleService-Info.plist não encontrado." >&2
    exit 1
fi

upload_symbols="${derived_data_path}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
if [ ! -x "${upload_symbols}" ]; then
    upload_symbols="$(find "${derived_data_path}/SourcePackages" -path '*/Crashlytics/upload-symbols' -type f -perm -u+x -print -quit 2>/dev/null || true)"
fi

if [ -z "${upload_symbols}" ] || [ ! -x "${upload_symbols}" ]; then
    echo "Crashlytics: upload-symbols não foi encontrado no checkout do Swift Package Manager." >&2
    exit 1
fi

"${upload_symbols}" \
    -gsp "${google_service_info}" \
    -p ios \
    "${archive_path}/dSYMs"

echo "Crashlytics: dSYMs enviados com sucesso."
