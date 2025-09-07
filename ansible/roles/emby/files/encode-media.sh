#!/bin/bash

lockfile="/run/lock/encode-media"

if [[ -f "${lockfile}" ]]; then
  echo "SKIPPING: an existing encode job is already running"
  exit 0
fi

touch "${lockfile}"

for dir in movies movies-tom movies-kids; do
  minsize="100M"
  srcdir="/mnt/media/encode/${dir}"
  outdir="/mnt/media/encode-tmp/${dir}"
  dstdir="/mnt/media/${dir}"

  find "${srcdir}" -type f -not -path '*/.*' -print0 | while IFS= read -r -d '' srcfile; do
    srcname="${srcfile##*/}"
    outfile="${outdir}/${srcname%.*}.mp4"
    dstfile="${dstdir}/${srcname%.*}.mp4"
    echo "Transcoding ${srcfile} -> ${outfile}"
    mkdir -p "${dstdir}"
    if HandBrakeCLI -i "${srcfile}" -o "${outfile}" -e nvenc_h265 -x "threads=1"; then
      echo "Moving ${outfile} -> ${dstfile}"
      mv "${outfile}" "${dstfile}"
      #echo "Deleting ${srcfile}"
      #rm -f "${srcfile}"
    fi
  done
done

rm "${lockfile}"

# vim: set ft=bash ts=2 sts=2 sw=2 et:
