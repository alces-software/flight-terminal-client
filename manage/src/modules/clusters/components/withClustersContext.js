import React from 'react';
import { Redirect } from 'react-router';
import { branch, compose, lifecycle, renderComponent } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';
import { renderRoutes } from 'react-router-config';
import { auth, showSpinnerUntil } from 'flight-reactware';

import launchUsers from '../../launchUsers';

import * as actions from '../actions';

const ClustersContext = ({ route }) => {
  return renderRoutes(route.routes);
};

const enhance = compose(
  connect(createStructuredSelector({
    authUser: auth.selectors.currentUserSelector,
    user: launchUsers.selectors.currentUser,
    userRetrieval: launchUsers.selectors.retrieval,
  })),

  branch(
    ({ authUser }) => !authUser,
    renderComponent(() => <Redirect to={'/'} />),
  ),

  showSpinnerUntil(
    ({ userRetrieval }) => userRetrieval.initiated && !userRetrieval.pending
  ),

  lifecycle({
    componentDidMount: function componentDidMount() {
      const { dispatch, user } = this.props;
      if (user != null) {
        const request = dispatch(actions.loadClustersConsumingCredits(user));
        if (request) {
          request.catch(error => error);
        }
      }
    },

    componentWillReceiveProps: function componentWillReceiveProps(nextProps) {
      const { dispatch, user } = this.props;
      const nextUserId = ( nextProps.user || {} ).id;
      const thisUserId = ( user || {} ).id;
      if (nextUserId !== thisUserId) {
        const request = dispatch(actions.loadClustersConsumingCredits(nextProps.user));
        if (request) {
          request.catch(error => error);
        }
      }
    },
  }),
);

export default enhance(ClustersContext);
