#!/bin/bash

for dir in movies movies-tom movies-kids documentaries; do
  minsize="100M"
  srcdir="/mnt/media/syncthing/${dir}"
  dstdir="/mnt/media/${dir}"

  find "${srcdir}" -type f -size +${minsize} -not -path '*/.*' -not -iname '*.iso' -print0 | while IFS= read -r -d '' srcfile; do
    dstfile="${dstdir}/${srcfile##*/}"
    echo "${srcfile} -> ${dstfile}"
    mkdir -p "${dstdir}"
    mv "${srcfile}" "${dstfile}"
  done

  encodedir="/mnt/media/encode/${dir}"
  find "${srcdir}" -type f -size +${minsize} -iname '*.iso' -not -path '*/.*' -print0 | while IFS= read -r -d '' srcfile; do
    dstfile="${encodedir}/${srcfile##*/}"
    echo "${srcfile} -> ${dstfile}"
    mkdir -p "${dstdir}"
    mv "${srcfile}" "${dstfile}"
  done
done

for dir in tv tv-tom tv-kids docuseries; do
  srcdir="/mnt/media/syncthing/${dir}"
  find "${srcdir}" -type f -size +10M -not -path '*/.*' -not -iname '*.iso' -print0 | while IFS= read -r -d '' srcfile; do
    dstfile="/mnt/media/${dir}/$(echo "${srcfile}" | cut -c $((${#srcdir} + 2))-)"
    dstdir="$(dirname "${dstfile}")"
    echo "${srcfile} -> ${dstfile}"
    mkdir -p "${dstdir}"
    mv "${srcfile}" "${dstfile}"
  done
done

# vim: set ft=bash ts=2 sts=2 sw=2 et:
