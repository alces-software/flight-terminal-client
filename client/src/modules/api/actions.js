/*=============================================================================
 * Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
 *
 * This file is part of Flight Launch.
 *
 * All rights reserved, see LICENSE.txt.
 *===========================================================================*/

export function fetchOneByLookupKey(baseUrl, key, value) {
  const url = new URL(baseUrl, window.location.href);
  if (!(process.env.NODE_ENV === 'test' && url.searchParams === undefined)) {
    url.searchParams.append(`filter[${key}]`, value);
  }

  return fetch(url.href)
    .then((response) => {
      if (response.ok) {
        return response.json();
      } else {
        return response.json().then(j => Promise.reject(j));
      }
    })
    .then((jsonApiDoc) => {
      console.log('jsonApiDoc:', jsonApiDoc);  // eslint-disable-line no-console
      const entities = jsonApiDoc.data;
      console.log('entities:', entities);  // eslint-disable-line no-console
      console.log('entities.length:', entities.length);  // eslint-disable-line no-console
      if (entities.length < 1 || entities > 1) {
        return Promise.reject({
          errors: [{
            status: 404,
            title: 'Record not found',
            code: 'RECORD_NOT_FOUND',
          }]
        });
      }
      return entities[0];
    })
    .catch((error) => {
      if (process.env.NODE_ENV !== 'test') {
        console.log('fetchOneByLookupKey failed:', error);  // eslint-disable-line no-console
      }
      return Promise.reject(error);
    });
}
