import React from 'react';
import { Redirect } from 'react-router-dom';
import { makeMetaPages, makeMetaPageRouteConfigs } from 'flight-reactware';

import App from './components/App';
import Directory from './pages/Directory';
import Home from './pages/Home';
import Page from './components/Page';
import licenseData from './data/licenses.json';
import withSiteContext from './components/withSiteContext';

const metaPages = makeMetaPages(Page, {
  softwareLicenses: licenseData,
});

const metaPageRouteConfigs = makeMetaPageRouteConfigs(metaPages);
const notFoundRouteConfig = {
  component: metaPages.NotFound,
};

const redirects = {
};
const redirectRoutes = Object.keys(redirects).map((k) => {
  const target = redirects[k];
  return {
    path: k,
    exact: false,
    component: ({ location }) => ( // eslint-disable-line react/prop-types
      <Redirect
        to={{
          pathname: target(location),
          search: location.search,
        }}
      />
    ),
  };
});
const routes = [
  ...redirectRoutes,
  {
    component: App,
    routes: [
      ...metaPageRouteConfigs,
      {
        path: '/',
        exact: true,
        component: Home,
        title: 'Overview',
      },
      {
        path: '/sites/:siteId',
        component: withSiteContext(),
        routes: [
          {
            path: '/sites/:siteId/directory',
            exact: true,
            component: Directory,
            title: 'Directory',
            pageKey: 'Directory',
          },
        ],
      },
      {
        path: '/',
        component: withSiteContext(),
        routes: [
          {
            path: '/directory',
            exact: true,
            component: Directory,
            title: 'Directory',
            pageKey: 'Directory',
          },
        ],
      },
      notFoundRouteConfig,
    ],
  },
];

export default routes;
