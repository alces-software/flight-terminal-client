import { Container } from 'reactstrap';
import { branch, compose, nest, renderComponent } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';

import { showSpinnerUntil } from 'flight-reactware';

import * as selectors from '../selectors';
import LoadError from './LoadError';

const withCluster = compose(
  connect(createStructuredSelector({
    cluster: selectors.currentCluster,
    retrieval: selectors.retrieval,
    hostname: selectors.hostname,
  })),

  showSpinnerUntil(
    ({ retrieval }) => retrieval.initiated && !retrieval.pending
  ),

  branch(
    ({ retrieval }) => retrieval.rejected,
    renderComponent(nest(Container, LoadError)),
  ),
);

export default withCluster;
