<%@ MasterPage %>
<%@ Page UseMasterPage="/010/master.asp" %>

<asp:Content PlaceHolderID="meta_title">child title</asp:Content>

<asp:Content PlaceHolderID="meta_keywords">child keywords</asp:Content>

<asp:Content PlaceHolderID="meta_description">child description</asp:Content>

<asp:Content PlaceHolderID="headline">child headline</asp:Content>

<asp:Content PlaceHolderID="breadcrumbs_outer"></asp:Content>

<asp:Content PlaceHolderID="main_content">
<asp:ContentPlaceHolder id="inner_content">child content</asp:ContentPlaceHolder>
</asp:Content>

