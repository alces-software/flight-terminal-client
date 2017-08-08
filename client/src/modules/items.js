import { ContextLink, NavItem } from 'flight-reactware';
const { makeItem } = NavItem;
const { makeLink } = ContextLink;

const currentSite = process.env.REACT_APP_SITE;

export default function(tenantIdentifier) {
  const prefix = tenantIdentifier === 'default' ? '' : `${tenantIdentifier}/`;
  return [
    makeItem('About', 'home', makeLink(currentSite, `/${prefix}`)),
    makeItem('Launch', 'plane', makeLink(currentSite, `/${prefix}launch`)),
    makeItem('Access', 'key', makeLink(currentSite, `/${prefix}access`)),
  ];
}
