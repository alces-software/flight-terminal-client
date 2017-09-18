/*=============================================================================
 * Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
 *
 * This file is part of Flight Launch.
 *
 * All rights reserved, see LICENSE.txt.
 *===========================================================================*/
import { jsonApi } from 'flight-reactware';

export function loadTenant(identifier) {
  return (dispatch, getState) => {
    if (identifier == null) { identifier = 'default'; }
    const tenantsUrl = '/api/v1/tenants';
    const resource = {
      type: 'tenants',
      meta: {
        loadingStates: {
          key: identifier,
        },
      },
    };
    const action = jsonApi.actions.loadResourceByLookupKey(
      tenantsUrl,
      resource,
      'identifier',
      identifier,
    );
    return dispatch(action);
  };
}
