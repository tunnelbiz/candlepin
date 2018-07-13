/**
 * Copyright (c) 2009 - 2012 Red Hat, Inc.
 *
 * This software is licensed to you under the GNU General Public License,
 * version 2 (GPLv2). There is NO WARRANTY for this software, express or
 * implied, including the implied warranties of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
 * along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 *
 * Red Hat trademarks are not licensed under GPLv2. No permission is
 * granted to use or replicate Red Hat trademarks that are incorporated
 * in this software or its documentation.
 */
package org.candlepin.auth;

import org.candlepin.auth.permissions.PermissionFactory;

import org.candlepin.common.exceptions.BadRequestException;
import org.candlepin.model.User;
import org.candlepin.service.UserServiceAdapter;
import org.candlepin.service.model.UserInfo;

import org.xnap.commons.i18n.I18n;

import javax.inject.Inject;
import javax.inject.Provider;

/**
 * UserAuth
 */
public abstract class UserAuth implements AuthProvider {

    protected UserServiceAdapter userServiceAdapter;
    protected Provider<I18n> i18nProvider;
    protected PermissionFactory permissionFactory;

    @Inject
    public UserAuth(UserServiceAdapter userServiceAdapter, Provider<I18n> i18nProvider) {
        this.userServiceAdapter = userServiceAdapter;
        this.i18nProvider = i18nProvider;

        this.permissionFactory = new PermissionFactory();
    }

    /**
     * Creates a user principal for a given username
     */
    protected Principal createPrincipal(String username) {
        UserInfo user = this.userServiceAdapter.findByLogin(username);

        if (user == null) {
            throw new BadRequestException(this.i18nProvider.get().tr("User not found: {0}", username));
        }

        // TODO: This creates a lot of object churn. We should probably update this later in a way
        // that can do permission checking without creating piles of objects that we just throw away
        // without ever using them in the general case.
        return user.isSuperAdmin() != null && user.isSuperAdmin() ?
            new UserPrincipal(username, null, true) :
            new UserPrincipal(username,
                this.permissionFactory.createPermissions(user, user.getPermissions()), false);
    }


}
