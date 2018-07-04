import React from 'react';
import PropTypes from 'prop-types';
import { Container } from 'reactstrap';
import { Redirect } from 'react-router';
import { compose, branch, nest, renderComponent } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';
import { showSpinnerUntil } from 'flight-reactware';

import LoadError from '../components/LoadError';
import TerminalPage from './TerminalPage';
import services from '../../../modules/services';

const propTypes = {
  jwt: PropTypes.string.isRequired,
  site: PropTypes.shape({
    name: PropTypes.string.isRequired,
  }).isRequired,
  siteId: PropTypes.number.isRequired,
};

const env = {
  LANG: 'en_GB.UTF-8',
};

const DirectoryPage = ({ jwt, site, siteId }) => {
  const title = (
    <span>
      Directory terminal: {site.name}
    </span>
  );
  const overview = (
    <span>
      The terminal below contains the Flight Directory CLI tool for your site,
      which you can use to manage your sites users and groups.
    </span>
  );

  return (
    <TerminalPage
      auth={{
        jwt: jwt,
        siteId: siteId
      }}
      columns={120}
      overview={overview}
      socketIOPath={process.env.REACT_APP_TERMINAL_SERVICE_SOCKET_IO_PATH}
      socketIOUrl={process.env.REACT_APP_TERMINAL_SERVICE_URL}
      termProps={{
        env: env,
      }}
      title={title}
    />
  );
};

DirectoryPage.propTypes = propTypes;

const enhance = compose(
  connect(createStructuredSelector({
    jwt: (state) => state.auth.ssoToken,
    retrieval: services.selectors.retrieval,
    site: services.selectors.site,
    siteId: services.selectors.siteId,
  })),

  showSpinnerUntil(
    ({ retrieval }) => retrieval.initiated && !retrieval.pending
  ),

  branch(
    ({ retrieval }) => retrieval.rejected,
    renderComponent(nest(Container, LoadError)),
  ),

  branch(
    ({ site }) => !site,
    renderComponent(() => <Redirect to="/" />),
  )
);

export default enhance(DirectoryPage);