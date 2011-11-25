/*
 * TNStropheUtils.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

stripHTMLCharCode = function(str)
{
    str = str.replace(/&amp;/g, '&');
    str = str.replace(/&nbsp;/g, ' ');
    str = str.replace(/&quote;/g, '\"');
    str = str.replace(/&apos;/g, '\'');
    str = str.replace(/&lt;/g, '<');
    str = str.replace(/&gt;/g, '>');
    str = str.replace(/&agrave;/g, 'à');
    str = str.replace(/&ccedil;/g, 'ç');
    str = str.replace(/&egrave;/g, 'è');
    str = str.replace(/&eacute;/g, 'é');
    str = str.replace(/&ecirc;/g, 'ê');
    return str;
}